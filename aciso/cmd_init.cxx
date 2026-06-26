#include "aciso.hxx"

static const char* DEFAULT_MAIN_ARC = R"(// Artemis entry point
int main() {
    return 0;
}
)";

void cmd_init(bool use_toml) {
    const std::string ext = use_toml ? ".toml" : ".json";

    if (fs::exists("aciso" + ext) || fs::exists("acm" + ext)) {
        err("project already initialised (aciso" + ext + " or acm" + ext + " exists)");
        return;
    }

    // Read project name from CWD
    std::string name = fs::current_path().filename().string();

    if (use_toml) {
        write_file_str("aciso.toml",
            "[project]\n"
            "name = \"" + name + "\"\n"
            "version = \"0.1.0\"\n"
            "main = \"src/main.arc\"\n"
            "owner = \"\"\n"
            "authors = []\n"
            "\n"
            "[build]\n"
            "output_dir = \"build/\"\n"
            "source_dir = \"src/\"\n"
            "\n"
            "[symbol]\n"
            "defined_symbols = []\n"
            "\n"
            "[targets]\n"
            "main_f = [\"dll\", \"so\", \"dylib\"]\n"
        );
        write_file_str("acm.toml",
            "[package]\n"
            "name = \"" + name + "\"\n"
            "version = \"0.1.0\"\n"
            "authors = []\n"
            "\n"
            "[dependencies]\n"
            "\n"
            "[dev-dependencies]\n"
        );
    } else {
        nlohmann::json build;
        build["project"] = {
            {"name", name}, {"version", "0.1.0"},
            {"main", "src/main.arc"}, {"owner", ""}, {"authors", nlohmann::json::array()}
        };
        build["build"] = {{"output_dir", "build/"}, {"source_dir", "src/"}};
        build["symbol"] = {{"defined_symbols", nlohmann::json::array()}};
        build["targets"] = {{"main_f", nlohmann::json::array({"dll", "so", "dylib"})}};
        write_file_str("aciso.json", build.dump(2));

        nlohmann::json pkg;
        pkg["package"] = {
            {"name", name}, {"version", "0.1.0"}, {"authors", nlohmann::json::array()}
        };
        pkg["dependencies"]     = nlohmann::json::object();
        pkg["dev-dependencies"] = nlohmann::json::object();
        write_file_str("acm.json", pkg.dump(2));
    }

    ensure_dir("src");
    if (!fs::exists("src/main.arc"))
        write_file_str("src/main.arc", DEFAULT_MAIN_ARC);

    ensure_dir("build");
    ensure_dir("modules");

    ok("initialised project \"" + name + "\" (" + ext.substr(1) + " format)");
}

void cmd_deinit() {
    bool removed = false;
    for (const auto& f : {"aciso.toml","aciso.json","acm.toml","acm.json","acm.lock"}) {
        if (fs::exists(f)) { fs::remove(f); removed = true; }
    }
    if (!removed) {
        warn("no manifest files found");
        return;
    }
    ok("removed manifests; source files preserved");
}
