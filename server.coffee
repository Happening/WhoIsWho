Db = require 'db'
Plugin = require 'plugin'
{tr} = require 'i18n'

exports.onInstall = (config) !->
	#run it through config
	exports.onConfig(config)

#Add field settings to the database under fields
exports.onConfig = (config) !->

	#sets custom fields
	custom = {}
	for k,v of config
		if k.substring(0, 6) is 'custom'
			log v.longText
			log JSON.stringify(v)
			v.longText = v.longText.charAt(0).toUpperCase()+v.longText.substr(1)
			if v.value isnt 'delete'
				custom[k] = v
				custom[k].value = true
				config[k] = null
			else
				Db.shared.remove 'custom', k
				config[k] = null

	customId = parseInt config.cId
	config.cId = null
	config.type = null #annoying side effect
	
	#write
	Db.shared.merge 'fields', config
	Db.shared.merge 'custom', custom
	Db.shared.set 'customId', customId

	#check if primary has a value, if not: set a default.
	if not Db.shared.peek('fields', 'primary')? or Db.shared.peek('fields', 'primary') is ""
		Db.shared.set('fields', 'primary', tr("Describe yourself briefly"))

exports.client_saveInfo = (value) !->
	#loop over keys, if it is an empty string, apply null so it is removed.
	for k,v of value
		if v.trim() is "" then value[k] = null
	Db.shared.merge Plugin.userId(), value

exports.onPhoto = (info, key) !->
	Db.shared.set Plugin.userId(), key, info

exports.client_removePhoto = (key) !->
	Db.shared.set Plugin.userId(), key, null