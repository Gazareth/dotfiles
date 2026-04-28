pub enum SnapshotLanguage {
    Lua,
    JavaScript,
    TypeScript,
    Python,
    Unknown,
}

pub fn detect(filetype: &str) -> SnapshotLanguage {
    match filetype {
        "lua"        => SnapshotLanguage::Lua,
        "javascript" => SnapshotLanguage::JavaScript,
        "typescript" => SnapshotLanguage::TypeScript,
        "python"     => SnapshotLanguage::Python,
        _            => SnapshotLanguage::Unknown,
    }
}
