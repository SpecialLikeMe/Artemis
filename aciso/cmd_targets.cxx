#include "aciso.hxx"

void cmd_add(const std::string& filename) {
    std::string type = type_from_filename(filename);
    std::string stem = fs::path(filename).stem().string();

    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("targets")) cfg.data["targets"] = nlohmann::json::object();

    // Detect source file
    std::string src_dir = "src/";
    if (cfg.data.contains("build")) src_dir = cfg.data["build"].value("source_dir", src_dir);
    std::string source = src_dir + stem + ".arc";

    nlohmann::json entry;
    entry["source"] = source;
    entry["type"]   = type;
    cfg.data["targets"][filename] = entry;
    cfg.save();
    ok("added target \"" + filename + "\" (" + type + ") <- " + source);
}

void cmd_addf(const std::string& filename, const std::string& type) {
    std::string stem = fs::path(filename).stem().string();

    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("targets")) cfg.data["targets"] = nlohmann::json::object();

    std::string src_dir = "src/";
    if (cfg.data.contains("build")) src_dir = cfg.data["build"].value("source_dir", src_dir);
    std::string source = src_dir + stem + ".arc";

    nlohmann::json entry;
    entry["source"] = source;
    entry["type"]   = type;
    cfg.data["targets"][filename] = entry;
    cfg.save();
    ok("added target \"" + filename + "\" (" + type + ") <- " + source);
}

void cmd_rmt(const std::string& target_name) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("targets") || !cfg.data["targets"].contains(target_name)) {
        err("target not found: " + target_name);
        return;
    }
    cfg.data["targets"].erase(target_name);
    cfg.save();
    ok("removed target " + target_name);
}

void cmd_lst() {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("targets") || cfg.data["targets"].empty()) {
        info("no targets defined");
        return;
    }

    std::string proj_name = "out";
    std::string main_src  = "src/main.arc";
    if (cfg.data.contains("project")) {
        proj_name = cfg.data["project"].value("name", proj_name);
        main_src  = cfg.data["project"].value("main", main_src);
    }

    std::cout << "Build targets:\n";
    for (auto& [key, val] : cfg.data["targets"].items()) {
        if (key == "main_f") {
            std::string types;
            if (val.is_array()) for (const auto& t : val) { if (!types.empty()) types += ", "; types += t.get<std::string>(); }
            std::cout << "  main_f  [" << types << "]  " << main_src << " -> build/" << proj_name << ".<type>\n";
        } else {
            std::string src = val.is_object() ? val.value("source", "?") : main_src;
            std::string type = val.is_object() ? val.value("type", "?") : val.get<std::string>();
            std::cout << "  " << key << "  [" << type << "]  " << src << "\n";
        }
    }
}
