#pragma once
#include "json.hxx"
#include "toml.hxx"
#include <string>
#include <fstream>
#include <filesystem>
#include <stdexcept>

namespace fs = std::filesystem;

struct Config {
    nlohmann::json data;
    std::string path;

    static Config load(const std::string& p) {
        Config c;
        c.path = p;
        std::ifstream f(p);
        if (!f) throw std::runtime_error("cannot open config: " + p);
        std::string content((std::istreambuf_iterator<char>(f)),
                            std::istreambuf_iterator<char>());
        if (p.size() >= 5 && p.substr(p.size()-5) == ".toml")
            c.data = toml::loads(content);
        else
            c.data = nlohmann::json::parse(content, nullptr, false);
        if (c.data.is_discarded()) c.data = nlohmann::json::object();
        return c;
    }

    void save() const { save_to(path); }

    void save_to(const std::string& p) const {
        std::ofstream f(p);
        if (!f) throw std::runtime_error("cannot write config: " + p);
        if (p.size() >= 5 && p.substr(p.size()-5) == ".toml")
            f << toml::dumps(data);
        else
            f << data.dump(2);
    }
};

// Locate a config file by prefix, preferring .toml then .json
inline std::string find_config(const std::string& prefix) {
    if (fs::exists(prefix + ".toml")) return prefix + ".toml";
    if (fs::exists(prefix + ".json")) return prefix + ".json";
    return "";
}

inline bool project_uses_toml() {
    return fs::exists("aciso.toml");
}

inline std::string cfg_ext() {
    return project_uses_toml() ? ".toml" : ".json";
}

inline Config load_build_config() {
    std::string p = find_config("aciso");
    if (p.empty()) throw std::runtime_error("no aciso.json or aciso.toml found in current directory");
    return Config::load(p);
}

inline Config load_pkg_config() {
    std::string p = find_config("acm");
    if (p.empty()) throw std::runtime_error("no acm.json or acm.toml found in current directory");
    return Config::load(p);
}

inline Config load_lock() {
    // lock file is always TOML
    if (!fs::exists("acm.lock")) {
        Config c;
        c.path = "acm.lock";
        c.data = nlohmann::json::object();
        c.data["version"] = 1;
        c.data["package"] = nlohmann::json::array();
        return c;
    }
    Config c;
    c.path = "acm.lock";
    std::ifstream f("acm.lock");
    std::string content((std::istreambuf_iterator<char>(f)),
                        std::istreambuf_iterator<char>());
    c.data = toml::loads(content);
    return c;
}

inline void save_lock(const Config& c) {
    std::ofstream f("acm.lock");
    f << toml::dumps(c.data);
}
