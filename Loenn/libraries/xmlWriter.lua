local logging=require("logging")
local xml2lua = require("lib.xml2lua.xml2lua")

--- implement toXml from xml2lua(it isn't in the main xml2lua instance)
--- liscensed under MIT from Manoel Campos da Silva Filho
local xmlWriter = {}
xmlWriter.pretty=true
local function getSingleChild(tb)
    local count = 0
    for _ in pairs(tb) do
      count = count + 1
    end
    if (count == 1) then
        for k, _ in pairs(tb) do
            return k
        end
    end
    return nil
end
local function getFirstValue(tb)
    if type(tb) == "table" then
        for _, v in pairs(tb) do
            return v
        end
        return nil
    end
  
    return tb
end
function xmlWriter.isChildArray(obj)
    for tag, _ in pairs(obj) do
      if (type(tag) == 'number') then
        return true
      end
    end
    return false
end
function xmlWriter.isTableEmpty(obj)
    for k, _ in pairs(obj) do
      if (k ~= '_attr') then
        return false
      end
    end
    return true
end
function xmlWriter.getSpaces(level)
    local spaces = ''
    if (xmlWriter.pretty) then
      spaces = string.rep(' ', level * 2)
    end
    return spaces
  end
local function attrToXml(attrTable)
    local s = ""
    attrTable = attrTable or {}
  
    for k, v in pairs(attrTable) do
        s = s .. " " .. k .. "=" .. '"' .. v .. '"'
    end
    return s
end
function xmlWriter.addTagValueAttr(tagName, tagValue, attrTable, level)
    local attrStr = attrToXml(attrTable)
    local spaces = xmlWriter.getSpaces(level)
    if (tagValue == '') then
      table.insert(xmlWriter.xmltb, spaces .. '<' .. tagName .. attrStr .. '/>')
    else
      table.insert(xmlWriter.xmltb, spaces .. '<' .. tagName .. attrStr .. '>' .. tostring(tagValue) .. '</' .. tagName .. '>')
    end
end
function xmlWriter.startTag(tagName, attrTable, level)
    local attrStr = attrToXml(attrTable)
    local spaces = xmlWriter.getSpaces(level)
    if (tagName ~= nil) then
      table.insert(xmlWriter.xmltb, spaces .. '<' .. tagName .. attrStr .. '>')
    end
end
function xmlWriter.endTag(tagName, level)
    local spaces = xmlWriter.getSpaces(level)
    if (tagName ~= nil) then
      table.insert(xmlWriter.xmltb, spaces .. '</' .. tagName .. '>')
    end
end
function xmlWriter.parseTableToXml(obj, tagName, level)
    if (tagName ~= '_attr') then
      if (type(obj) == 'table') then
        if (xmlWriter.isChildArray(obj)) then
          for _, value in pairs(obj) do
            xmlWriter.parseTableToXml(value, tagName, level)
          end
        elseif xmlWriter.isTableEmpty(obj) then
          xmlWriter.addTagValueAttr(tagName, "", obj._attr, level)
        else
          xmlWriter.startTag(tagName, obj._attr, level)
          for tag, value in pairs(obj) do
            xmlWriter.parseTableToXml(value, tag, level + 1)
          end
          xmlWriter.endTag(tagName, level)
        end
      else
        xmlWriter.addTagValueAttr(tagName, obj, nil, level)
      end
    end
end
function xmlWriter.toXml(tb, tableName, level)
    xmlWriter.xmltb = {}
    level = level or 0
    local singleChild = getSingleChild(tb)
    tableName = tableName or singleChild
  
    if (singleChild) then
      xmlWriter.parseTableToXml(getFirstValue(tb), tableName, level)
              else
      xmlWriter.parseTableToXml(tb, tableName, level)
    end
  
    if (xmlWriter.pretty) then
      return table.concat(xmlWriter.xmltb, '\n')
    end
    return table.concat(xmlWriter.xmltb)
end
return xmlWriter