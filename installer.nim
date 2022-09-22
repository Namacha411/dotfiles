import std/os
import std/sets
import strformat

var pathTable: OrderedSet[(string, string)]

if defined(windows):
    var
        home = getEnv("HOMEPATH")
        localAppData = getEnv("LOCALAPPDATA")
        psProfile = getEnv("PROFILE")
        config = &"{home}/.config"

    pathTable = toOrderedSet([
        ("./nvim/",                 &"{localAppData}/nvim/"),
        ("./wezterm/wezterm.lua",   &"{home}/.wezterm.lua"),
        ("./vim/.vimrc",            &"{home}/.vimrc"),
        ("./starship.toml",         &"{config}/starship.toml"),
        ("./Microsoft.PowerShell_profile.ps1",  &"{psProfile}"),
    ])
elif defined(linux):
    var
        home = getEnv("HOME")
        config = &"{home}/.config"

    pathTable = toOrderedSet([
        ("./vim/.vimrc",            &"{home}/.vimrc"),
        ("./nvim/",                 &"{config}/nvim/"),
        ("./starship.toml",         &"{config}/starship.toml"),
        ("./wezterm/wezterm.lua",   &"{config}/wezterm/.wezterm.lua"),
    ])
elif defined(macos):
    var e: ref OSError
    new(e)
    e.msg = "the request to the OS failed."
    raise e
else:
    var e: ref OSError
    new(e)
    e.msg = "the request to the OS failed."
    raise e

for (src, dest) in pathTable:
    createSymlink(src, dest)
