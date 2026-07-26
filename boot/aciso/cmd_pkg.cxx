#include "aciso.hxx"
#include <algorithm>

// --- helpers ---

static std::string tmp_clone_dir(const std::string& name) {
    return (fs::temp_directory_path() / ("aciso_pkg_" + name)).string();
}

static nlohmann::json read_export(const std::string& dir) {
    for (const auto& f : {"export.toml", "export.json"}) {
        std::string p = dir + "/" + f;
        if (!fs::exists(p)) continue;
        if (std::string(f) == "export.toml") {
            return toml::loads(read_file_str(p));
        } else {
            auto j = nlohmann::json::parse(read_file_str(p), nullptr, false);
            if (!j.is_discarded()) return j;
        }
    }
    return nullptr;
}

// --- install ---

void cmd_install(const std::string& pkg_name, const std::string& url) {
    if (pkg_name == ".") { err("invalid package name \".\""); return; }
    std::string tmp = tmp_clone_dir(pkg_name);
    if (fs::exists(tmp)) fs::remove_all(tmp);

    info("cloning " + url + " ...");
    if (run_cmd("git clone --depth=1 " + url + " \"" + tmp + "\"") != 0) {
        err("git clone failed for " + url);
        return;
    }

    nlohmann::json exp = read_export(tmp);
    if (exp.is_null() || !exp.contains("export")) {
        err("no export.[toml|json] found in package or missing 'export' array");
        fs::remove_all(tmp);
        return;
    }

    std::string dest = "modules/" + pkg_name;
    ensure_dir(dest);

    std::string combined_hash_input;
    for (const auto& rel : exp["export"]) {
        std::string src = tmp + "/" + rel.get<std::string>();
        std::string dst = dest + "/" + rel.get<std::string>();
        ensure_dir(fs::path(dst).parent_path().string());
        if (!fs::exists(src)) {
            warn("export file not found: " + src);
            continue;
        }
        fs::copy_file(src, dst, fs::copy_options::overwrite_existing);
        combined_hash_input += read_file_str(src);
        info("installed " + dst);
    }

    fs::remove_all(tmp);

    std::string pkg_hash = sha256(combined_hash_input);

    // Update acm.json/toml
    try {
        Config acm = load_pkg_config();
        if (!acm.data.contains("dependencies"))
            acm.data["dependencies"] = nlohmann::json::object();
        acm.data["dependencies"][pkg_name] = url;
        acm.save();
    } catch (...) {}

    // Update acm.lock
    Config lock = load_lock();
    if (!lock.data.contains("package") || !lock.data["package"].is_array())
        lock.data["package"] = nlohmann::json::array();

    // Remove existing entry with same name
    auto& pkgs = lock.data["package"];
    pkgs.erase(std::remove_if(pkgs.begin(), pkgs.end(),
        [&](const nlohmann::json& p){ return p.value("name","") == pkg_name; }),
        pkgs.end());

    nlohmann::json entry;
    entry["name"]   = pkg_name;
    entry["source"] = url;
    entry["sha256"] = pkg_hash;
    pkgs.push_back(entry);
    save_lock(lock);

    ok("installed " + pkg_name);
}

// --- uninstall ---

void cmd_uninstall(const std::string& pkg_name) {
    fs::path dest = fs::path("modules") / pkg_name;
    if (!fs::exists(dest)) { err("package not installed: " + pkg_name); return; }
    fs::remove_all(dest);

    // Remove from acm
    try {
        Config acm = load_pkg_config();
        if (acm.data.contains("dependencies"))
            acm.data["dependencies"].erase(pkg_name);
        if (acm.data.contains("dev-dependencies"))
            acm.data["dev-dependencies"].erase(pkg_name);
        acm.save();
    } catch (...) {}

    // Remove from lock
    Config lock = load_lock();
    if (lock.data.contains("package")) {
        auto& pkgs = lock.data["package"];
        pkgs.erase(std::remove_if(pkgs.begin(), pkgs.end(),
            [&](const nlohmann::json& p){ return p.value("name","") == pkg_name; }),
            pkgs.end());
        save_lock(lock);
    }

    ok("uninstalled " + pkg_name);
}

// --- update ---

void cmd_update(const std::string& pkg_name) {
    try {
        Config acm = load_pkg_config();
        std::string url;
        if (acm.data.contains("dependencies") && acm.data["dependencies"].contains(pkg_name))
            url = acm.data["dependencies"][pkg_name].get<std::string>();
        else if (acm.data.contains("dev-dependencies") && acm.data["dev-dependencies"].contains(pkg_name))
            url = acm.data["dev-dependencies"][pkg_name].get<std::string>();
        else { err("package not found: " + pkg_name); return; }

        // remove old copy
        fs::path dest = fs::path("modules") / pkg_name;
        if (fs::exists(dest)) fs::remove_all(dest);

        cmd_install(pkg_name, url);
    } catch (const std::exception& e) { err(e.what()); }
}

// --- vald ---

void cmd_vald() {
    Config acm;
    try { acm = load_pkg_config(); } catch (const std::exception& e) { err(e.what()); return; }

    bool all_ok = true;
    auto check_deps = [&](const std::string& section) {
        if (!acm.data.contains(section)) return;
        for (auto& [name, _] : acm.data[section].items()) {
            fs::path p = fs::path("modules") / name;
            if (!fs::exists(p)) {
                err("missing package directory: modules/" + name);
                all_ok = false;
            }
        }
    };
    check_deps("dependencies");
    check_deps("dev-dependencies");

    if (all_ok) ok("all packages present in modules/");
}

// --- audit ---

void cmd_audit() {
    Config lock;
    try { lock = load_lock(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!lock.data.contains("package") || lock.data["package"].empty()) {
        info("no packages in lock file");
        return;
    }

    bool clean = true;
    for (const auto& pkg : lock.data["package"]) {
        std::string name   = pkg.value("name",   "");
        std::string stored = pkg.value("sha256",  "");

        if (name.empty()) continue;

        fs::path mod_dir = fs::path("modules") / name;
        if (!fs::exists(mod_dir)) {
            warn("package " + name + " not installed — run aciso install");
            continue;
        }

        // hash all files in the module directory
        std::string combined;
        for (auto& e : fs::recursive_directory_iterator(mod_dir))
            if (e.is_regular_file())
                combined += read_file_str(e.path().string());

        std::string actual = sha256(combined);
        if (actual == stored) {
            ok("verified " + name);
        } else {
            err("hash mismatch for " + name +
                "\n  expected: " + stored +
                "\n  actual:   " + actual);
            clean = false;
        }
    }
    if (clean) ok("audit passed — all hashes match");
}
