#include "aciso.hxx"
#include <algorithm>

void cmd_itarget(const std::string& symbol) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("symbol")) cfg.data["symbol"] = nlohmann::json::object();
    if (!cfg.data["symbol"].contains("defined_symbols"))
        cfg.data["symbol"]["defined_symbols"] = nlohmann::json::array();

    auto& syms = cfg.data["symbol"]["defined_symbols"];
    for (const auto& s : syms) {
        if (s.get<std::string>() == symbol) {
            warn("symbol already defined: " + symbol);
            return;
        }
    }
    syms.push_back(symbol);
    cfg.save();
    ok("defined symbol: " + symbol);
}

void cmd_utarget(const std::string& symbol) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    if (!cfg.data.contains("symbol") || !cfg.data["symbol"].contains("defined_symbols")) {
        warn("no symbols defined");
        return;
    }

    auto& syms = cfg.data["symbol"]["defined_symbols"];
    auto it = std::remove_if(syms.begin(), syms.end(),
        [&](const nlohmann::json& s){ return s.get<std::string>() == symbol; });

    if (it == syms.end()) { err("symbol not defined: " + symbol); return; }
    syms.erase(it, syms.end());
    cfg.save();
    ok("undefined symbol: " + symbol);
}
