do

-- Returns a table with `name` and `msgs`
local function get_msgs_user_chat(user_id, chat_id)
  local user_info = {}
  local uhash = 'user:'..user_id
  local user = redis:hgetall(uhash)
  local um_hash = 'msgs:'..user_id..':'..chat_id
  user_info.msgs = tonumber(redis:get(um_hash) or 0)
  user_info.name = user_print_name(user)..' ['..user_id..']'
  return user_info
end

local function chat_stats(chat_id)
  -- Users on chat
  local hash = 'chat:'..chat_id..':users'
  local users = redis:smembers(hash)
  local users_info = {}
  -- Get user info
  for i = 1, #users do
    local user_id = users[i]
    local user_info = get_msgs_user_chat(user_id, chat_id)
    table.insert(users_info, user_info)
  end
  -- Sort users by msgs number
  table.sort(users_info, function(a, b) 
      if a.msgs and b.msgs then
        return a.msgs > b.msgs
      end
    end)
  local text = 'کاربرای این گروه \n'
  for k,user in pairs(users_info) do
    text = text..user.name..' = '..user.msgs..'\n'
  end
  local file = io.open("./groups/lists/"..chat_id.."stats.txt", "w")
  file:write(text)
  file:flush()
  file:close() 
  send_document("chat#id"..chat_id,"./groups/lists/"..chat_id.."stats.txt", ok_cb, false)
  return --text
end

local function chat_stats2(chat_id)
  -- Users on chat
  local hash = 'chat:'..chat_id..':users'
  local users = redis:smembers(hash)
  local users_info = {}

  -- Get user info
  for i = 1, #users do
    local user_id = users[i]
    local user_info = get_msgs_user_chat(user_id, chat_id)
    table.insert(users_info, user_info)
  end

  -- Sort users by msgs number
  table.sort(users_info, function(a, b) 
      if a.msgs and b.msgs then
        return a.msgs > b.msgs
      end
    end)

  local text = 'لیست اعضای این گروه \n'
  for k,user in pairs(users_info) do
    text = text..user.name..' = '..user.msgs..'\n'
  end
  return text
end
-- Save stats, ban user
local function bot_stats()

  local redis_scan = [[
    local cursor = '0'
    local count = 0
    repeat
      local r = redis.call("SCAN", cursor, "MATCH", KEYS[1])
      cursor = r[1]
      count = count + #r[2]
    until cursor == '0'
    return count]]

  -- Users
  local hash = 'msgs:*:'..our_id
  local r = redis:eval(redis_scan, 1, hash)
  local text = 'کاربران : '..r

  hash = 'chat:*:users'
  r = redis:eval(redis_scan, 1, hash)
  text = text..'\nگروه ها: '..r
  return text
end
local function run(msg, matches)
  if matches[1]:lower() == 'تله سورنا' then -- Put everything you like :)
    local about = _config.about_text
    local name = user_print_name(msg.from)
    savelog(msg.to.id, name.." ["..msg.from.id.."] از دستور ربات اسفاده کرد ")
    return about
  end 
  if matches[1]:lower() == "لیست آمار" then
    if not is_momod(msg) then
      return "فقط برای مدیران !"
    end
    local chat_id = msg.to.id
    local name = user_print_name(msg.from)
    savelog(msg.to.id, name.." ["..msg.from.id.."] درخواست آمار گروه را داد ")
    return chat_stats2(chat_id)
  end
  if matches[1]:lower() == "آمار" then
    if not matches[2] then
      if not is_momod(msg) then
        return "مختص ادمین هاست فقط !"
      end
      if msg.to.type == 'گروه' then
        local chat_id = msg.to.id
        local name = user_print_name(msg.from)
        savelog(msg.to.id, name.." ["..msg.from.id.."] درخواست آمار گروه را داد ")
        return chat_stats(chat_id)
      else
        return
      end
    end
    if matches[2] == "تله دِو" then -- Put everything you like :)
      if not is_admin(msg) then
        return "مختص ادمین هاست فقط !"
      else
        return bot_stats()
      end
    end
    if matches[2] == "گروه" then
      if not is_admin(msg) then
        return "مختص ادمین هاست فقط !"
      else
        return chat_stats(matches[3])
      end
    end
  end
end
return {
  patterns = {
    "^(آمار)$",
    "^(لیست آمار)$",
    "^(آمار) (گروه) (%d+)",
    "^(آمار ربات) (تله دِو)",
		"^(تله سورنا)"
    }, 
  run = run
}

end
