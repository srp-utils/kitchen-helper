script_name('KitchenHelper');
script_version('2025-01-18');
script_dependencies('samp.events', 'inicfg');
script_author('https://samp-rp.online/members/1017623/');

local hook = require 'samp.events';
local inicfg = require 'inicfg';
local encoding = require 'encoding';
local u8 = encoding.UTF8;

encoding.default = 'cp1251';

local CONFIG_DIALOG_ID = 2003;
local CONFIG_FILE_NAME = 'srp-kitchen-helper.ini';

local autoCookItemId = nil;
local dishesDialogId = nil;

local state = inicfg.load({
  config = {
    autoRent = false,
    autoCook = true
  },
  stats = {
    rentCount = 0,
    cookCount = 0
  }
}, CONFIG_FILE_NAME);


function main()
  sampRegisterChatCommand('cook', showConfigDialog);

  while not isSampAvailable() do
    wait(100);
  end

  while true do
    wait(100);

    local result, button, list = sampHasDialogRespond(CONFIG_DIALOG_ID);

    if result and button == 1 then
      if list == 0 then
        state.config.autoRent = not state.config.autoRent;
      elseif list == 1 then
        state.config.autoCook = not state.config.autoCook;

        if not state.config.autoCook then
          autoCookItemId = nil;
        end
      elseif list == 6 then
        state.stats.cookCount = 0;
        state.stats.rentCount = 0;
      end

      saveConfig(state);
      showConfigDialog();
    end
  end
end

function hook.onShowDialog(id, style, title, button, button2, text)
  if isSRP() and title:equals('Кухня') then
    if state.config.autoRent and text:find('Аренда кухни') and button:equals('Заплатить') then
      sampSendDialogResponse(id, 1);

      return false;
    end

    if state.config.autoCook and style == DIALOG_STYLE_TABLIST_HEADERS and text:find('Блюдо') and button:equals('Ок') then
      dishesDialogId = id;

      if autoCookItemId then
        sampSendDialogResponse(id, 1);

        return false;
      end
    end

    if style == DIALOG_STYLE_MSGBOX and button:equals('Начать') then
      sampSendDialogResponse(id, 1);

      return false;
    end
  end
end

function hook.onSendDialogResponse(id, button, listboxId, input)
  if state.config.autoCook and id == dishesDialogId and button == 1 then
    autoCookItemId = listboxId;
  end
end

function hook.onServerMessage(color, text)
  if isSRP() then
    if state.config.autoCook then
      if color == -10270721 and (text:equals(' У вас нет нужных ингредиентов') or text:equals(' Нет места')) then
        autoCookItemId = nil;
      end
    end

    if color == 1790050303 and text:match('Вы приготовили.*: %d+/%d+') then
      state.stats.cookCount = state.stats.cookCount + 1;

      saveConfig(state);

      sampSendChat('/kitchen cooking');
    end

    if color == 1790050303 and text:find('Вы арендовали кухню на') then
      state.stats.rentCount = state.stats.rentCount + 1;

      saveConfig(state);

      sampSendChat('/kitchen cooking');
    end
  end
end

function isSRP()
  local serverName = sampGetCurrentServerName();

  return serverName:find('Samp%-Rp.Ru') ~= nil or serverName:find('SRP') ~= nil;
end

function showConfigDialog()
  if not isSRP() then
    return false;
  end

  local function getStatusCaption(status)
    return status and '{00ff00}автоматически' or '{ffa500}вручную';
  end

  local body = 
    'Аренда\t' .. getStatusCaption(state.config.autoRent) .. '\n' ..
    'Готовка\t' .. getStatusCaption(state.config.autoCook) .. '\n \n' ..
    'Блюд приготовлено\t' .. state.stats.cookCount .. '\n' ..
    'Плит арендовано\t' .. state.stats.rentCount .. '\n \n' ..
    'Сбросить статистику';

  sampShowDialog(CONFIG_DIALOG_ID, 'KitchenHelper', u8:decode(body), u8:decode('Выбрать'), u8:decode('Закрыть'), DIALOG_STYLE_TABLIST);
end

function saveConfig(data)
  inicfg.save(data, CONFIG_FILE_NAME);
end

 
local find = string.find;
local match = string.match;

function string.find(self, pattern)
  return find(self, u8:decode(pattern), init, plain);
end

function string.match(self, pattern)
  return match(self, u8:decode(pattern));
end

function string.equals(self, s2)
  return self == u8:decode(s2);
end
