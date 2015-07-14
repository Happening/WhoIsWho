Db = require 'db'
Plugin = require 'plugin'

exports.onInstall = (config) !->
	# set the counter to 0 on plugin installation
	log "WhoIsWho server installed called with:"
	log JSON.stringify( config )

#Add field settings to the database under fields
exports.onConfig = (config) !->

	#sets custom fields
	custom = {}
	for k,v of config
		if k.substring(0, 6) is 'custom'
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
		Db.shared.set('fields', 'primary', "Describe yourself briefly.")

exports.client_saveInfo = (value) !->
	Db.shared.merge Plugin.userId(), value