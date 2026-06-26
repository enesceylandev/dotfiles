local function parse_macro(value)
  return value
    :gsub('%^J', '\n') -- newline
    :gsub('%^M', '\r') -- carriage return
    :gsub('%^%[', '\27') -- ESC
    :gsub('%^%^', '^') -- literal ^
end

local function set_macros(registers)
  for reg, value in pairs(registers) do
    vim.fn.setreg(reg, parse_macro(value))
  end
end

-- Macros ---
set_macros {
  l = [[yoconsole.log('^[pa: ', ^[pa);^[^^]],
}
