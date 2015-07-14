Db = require 'db'
Plugin = require 'plugin'

exports.onInstall = (config) !->
	# set the counter to 0 on plugin installation
	log "WhoIsWho server installed called with:"
	log JSON.stringify( config )

#Add field settings to the dabase under fields
exports.onConfig = (config) !->
	log "Config:"
	log JSON.stringify( config )
	# data = config.hiddenValue #get bulk info
	# log "data:"
	# log JSON.stringify ( data )
	# config.hiddenValue = null #remove from config, so not to get confused

	# #set the value of all the fields from the config
	# log "data:"
	# log JSON.stringify( data )
	# for k,v of config
	# 	data[k].value = v

	#write
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
	config.type = null
	
	Db.shared.merge 'fields', config
	Db.shared.merge 'custom', custom
	Db.shared.set 'customId', customId


	#check if primary has a vlaue
	if not Db.shared.peek('fields', 'primary')? or Db.shared.peek('fields', 'primary') is ""
		Db.shared.set('fields', 'primary', "Describe yourself briefly.")

exports.client_saveInfo = (value) !->
	Db.shared.merge Plugin.userId(), value