#include "aciso.hxx"

void cmd_export(bool use_toml) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    std::string name    = "unnamed";
    std::string version = "0.1.0";
    if (cfg.data.contains("project")) {
        name    = cfg.data["project"].value("name",    name);
        version = cfg.data["project"].value("version", version);
    }

    // Collect all .arc files in src/ as default exports
    std::string src_dir = "src/";
    if (cfg.data.contains("build")) src_dir = cfg.data["build"].value("source_dir", src_dir);

    nlohmann::json export_list = nlohmann::json::array();
    for (const auto& f : collect_ext(src_dir, ".arc")) {
        // make path relative
        fs::path rel = fs::relative(f);
        export_list.push_back(rel.string());
    }

    if (use_toml) {
        std::string content =
            "[registry]\n"
            "package = \"" + name + "\"\n"
            "version = \"" + version + "\"\n"
            "\nexport = [\n";
        for (const auto& e : export_list)
            content += "    \"" + e.get<std::string>() + "\",\n";
        content += "]\n";
        write_file_str("export.toml", content);
        ok("created export.toml");
    } else {
        nlohmann::json exp;
        exp["registry"]["package"] = name;
        exp["registry"]["version"] = version;
        exp["export"]              = export_list;
        write_file_str("export.json", exp.dump(2));
        ok("created export.json");
    }
}

// ---- conv ----

void cmd_conv(bool to_toml) {
    if (to_toml) {
        // JSON → TOML
        for (const auto& pair : std::vector<std::pair<std::string,std::string>>{
                {"aciso", "aciso"}, {"acm", "acm"}}) {
            std::string src = pair.first + ".json";
            std::string dst = pair.second + ".toml";
            if (!fs::exists(src)) continue;
            Config c = Config::load(src);
            c.path = dst;
            c.save();
            fs::remove(src);
            ok("converted " + src + " -> " + dst);
        }
    } else {
        // TOML → JSON
        for (const auto& pair : std::vector<std::pair<std::string,std::string>>{
                {"aciso", "aciso"}, {"acm", "acm"}}) {
            std::string src = pair.first + ".toml";
            std::string dst = pair.second + ".json";
            if (!fs::exists(src)) continue;
            Config c = Config::load(src);
            c.path = dst;
            c.save();
            fs::remove(src);
            ok("converted " + src + " -> " + dst);
        }
    }
}
