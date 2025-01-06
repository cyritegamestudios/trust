local Loading = {}

Loading.LoadDependenciesAction = require('cylibs/actions/import_action')
Loading.LoadSettingsAction = require('loading/actions/load_settings')
Loading.Loadi18nAction = require('loading/actions/load_i18n')
Loading.LoadGlobalsAction = require('loading/actions/load_globals')
Loading.LoadLoggerAction = require('loading/actions/load_logger')
Loading.LoadThemeAction = require('loading/actions/load_theme')

return Loading

