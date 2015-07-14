Db = require 'db'
Dom = require 'dom'
Form = require 'form'
Icon = require 'icon'
Modal = require 'modal'
Obs = require 'obs'
Page = require 'page'
Photo = require 'photo'
Plugin = require 'plugin'
Server = require 'server'
Ui = require 'ui'

renderHeader = (id) ->
	Icon.render
		# data: 'silhouette'
		data: Photo.url( Plugin.userAvatar(id), 200 )
		size: 200
		content: !->
			Dom.style
				width: '100%'
				height: '150px'
				Box: 'bottom right'
				display: 'flex'
				# margin: '-8px 0px 0px 0px'
			Dom.span !->
				Dom.style
					fontSize: '24px'
					color: '#FFF'
					margin: '0px 18px 10px 0px'
				Dom.text Plugin.userName(id)

addField = (key, field, input, sep = true) !->
	userValue = null
	if not input
		id = Page.state.get("?id")
		userValue = Db.shared.get(id, key)
		if !userValue? then return

	if sep then Form.sep()
	Dom.div !->
		Dom.p !->
			Dom.style margin: '10px 0px 10px 10px'
			Dom.text field.longText
		Dom.p !->
			Dom.style
				margin: '0px 10px 10px 0px'
				textAlign: 'right'
				clear: 'both'
				fontSize: '21px'
			if input
				Form.input
					name: key
					text: field.longText
					value: Db.shared.get(Plugin.userId(), key)
					onSave: (val) !->
						log key
						d = {}
						d[key] = val
						log "---------------"
						log d
						Server.sync "saveInfo", d, !->
							Db.shared.set Plugin.userId(), d
			else
				Dom.userText userValue

renderUser = ->
	id = Page.state.get("?id")
	Dom.style padding: '0px'

	#header img
	renderHeader id

	#content
	Dom.section !->
		empty = true
		if Db.shared.peek(id, 'primary')?
			empty = false
			addField('primary', {longText: Db.shared.get('fields', 'primary')}, false, false)

		([k,v] for k,v of Db.shared.get('fields')).forEach ([key, field]) !-> #forEach hack
			if key isnt 'primary'
				empty = false
				addField(key, field, false)

		([k,v] for k,v of Db.shared.get('custom')).forEach ([key, field]) !-> #forEach hack
			empty = false
			addField(key, field, false)

		if empty then Dom.userText Form.smileyToEmoji("User has not filled in any information yet :(")

renderForm = ->	
	id = Page.state.get("?id")
	Dom.style padding: '0px'
	#header img
	renderHeader id

	# content
	Dom.section !->
		addField('primary', {longText: Db.shared.get('fields', 'primary')}, true, false)

		([k,v] for k,v of Db.shared.get('fields')).forEach ([key, field]) !-> #forEach hack
			if key isnt 'primary'
				addField(key, field, true)

		([k,v] for k,v of Db.shared.get('custom')).forEach ([key, field]) !->
			addField(key, field, true)

	Form.setPageSubmit (value) !->
		Server.sync 'saveInfo', value, !->
			Db.shared.set(Plugin.userId(), value)
		Page.back()
	, 0

	Dom.css
		'.form-text-wrap':
			padding: '20px 4px 8px 4px'
		'.description':
			marginLeft: '5px'
			marginBottom: '4px'
			display: 'block'

renderOverview = ->
	#Urge the user to enter his own details
	if not Db.shared.peek(Plugin.userId(), 'primary')?
		Page.setFooter
			label: "Tell others about yourself"
			action: !->
				Page.nav ['form']	

	#Render overview of all users
	Dom.section !->
		imgSize = (Page.width()-20) / Math.floor((Page.width()-20)/124)
		log Page.width() + " - " + imgSize

		Dom.style
			padding: '3px'
			Box: 'top'
			flexWrap: 'wrap'
			width: '100%'
		Dom.css
			'.square':
				padding: '3px'
				boxSizing: 'border-box'
				borderRadius: '3px'
				height: imgSize
				width: imgSize
				# position: 'relative'

			'.squareContent':
				color: '#FFF'
				boxShadow: '0 2px 0 rgba(0, 0, 0, 0.15)'
			
		Plugin.users.iterate (user) !->
			Dom.div !->
				Dom.addClass "square"	

				Icon.render
					# data: 'silhouette'
					data: Photo.url( user.get('avatar'), imgSize )
					size: imgSize
					content: !->
						Dom.addClass 'squareContent'	
						Dom.style
							height: '100%'
							width: '100%'
							# display: 'block'
							
						Dom.div !->
							Dom.style
								height: '100%'
								width: '100%'
								# position: 'absolute'
								background: 'linear-gradient(to top, rgba(0,0,0,0.55) 0%,rgba(0,0,0,0) 60%)'
								Box: 'vertical bottom left'
								padding: '5px'
								boxSizing: 'border-box'


							Dom.span !->
								Dom.style fontSize: '18px'
								Dom.text user.get('name')
							if Db.shared.get(user.key(), 'primary')
								Dom.span !->
									Dom.style
										width: '100%'
										overflow: 'hidden'
										whiteSpace: 'nowrap'
										textOverflow: 'ellipsis'
									Dom.userText Db.shared.peek(user.key(), 'primary')

					Dom.onTap !->
						log user.key(), Plugin.userId()
						if parseInt(user.key()) is Plugin.userId()
							Page.nav ['form'] #edit yourself
						else 
							Page.nav {0:"user", "?id": user.key()} #view other user's details			
				
			
#Settings view.
exports.renderSettings = !->
	fieldsOptions = 
		'name':
			longText: 'Name'
			type: 'text'
			value: false
		'function':
			longText: 'Function or profession'
			type: 'text'
			value: false
		'email':
			longText: 'Email address'
			type: 'email'
			value: false
		'facebook':
			longText: 'Facebook name'
			type: 'facebook'
			value: false

	#get fieldsOptions from the server if it's there.
	if Db.shared.get('fields')
		fieldsOptions = Db.shared.get('fields')
		log JSON.stringify(fieldsOptions)

	Dom.h5 "Change the information users can provide"

	# Form.box !->
	Dom.h3 "Primary question:"
	Form.input
		name: "primary"
		text: "Describe yourself briefly."
		value: Db.shared.get('fields', 'primary')

	Dom.h3 "Other fields:"

	fieldsO = Obs.create(fieldsOptions)

	makeComplexCheck = (opts) !->
		checkE = null
		divE = null
		inputE = Dom.div !->
			divE = Dom.get()
			if opts.sep is 'top'
				Form.sep()
			Form.box !->
				if txt = opts.text
					Dom.text txt
				if sub=opts.sub
					Dom.div sub
				
				[handleChange,orgValue] = Form.makeInput opts

				if opts.check
					checkE = Form.check(simple: true, value: opts.value.value)
					Dom.onTap (evt) !->
						checked = !checkE.prop('checked')
						checkE.prop 'checked', checked
						handleChange 
							value: checked
							longText: opts.text
							type: opts.sub

				if opts.trash
					Icon.render(data: 'trash')
					Dom.onTap (evt) !->
						Modal.confirm "are you sure you want to remove " + orgValue.longText + "?", !->
							handleChange 
								value: 'delete'
							divE.style display: 'none'

			if opts.sep is 'bottom'
				Form.sep()


	fieldsO.iterate (f) !->
		if f.key() isnt 'primary'
			makeComplexCheck
				text: f.get('longText')
				name: f.key()
				check: true
				value: 
					value: Db.shared.get('fields', f.key(), 'value') ? true
					longText: f.get('longText')
					type: f.get('type')
			Form.sep()

	#custom fields
	customO = Obs.create Db.shared.get('custom') ? {}

	# Obs.observe !->
	maxCustoms = Db.shared.get('customId') ? 0
	customIdH = Form.hidden('cId', maxCustoms)

	log "redoing customO"
	customO.iterate (c) !->
		log "iterating over " + c.get('longText')
		makeComplexCheck
			text: c.get('longText')
			name: c.key()
			sub: c.get('type')
			check: false
			trash: true
			sep: 'bottom'
			value: 
				longText: c.get('longText')
				type: c.get('type')

	#Add field
	Dom.div !->
		Dom.style
			# color: Plugin.colors().highlight
			padding: '12px 8px'
		Dom.text "+ Custom field"
		
		addCallback = (value) !->
			log "commited: "
			log JSON.stringify( value )
			++maxCustoms
			customO.set ('custom' + maxCustoms), {'longText': value[0], 'type': value[1], value:true}
			customIdH.value(maxCustoms)
		Dom.onTap !->
			result = []
			Modal.show "Custom field", !->
				Dom.text "Name your custom field"
				Form.input
					text: '' 
					onChange: (v) !-> result[0] = v
				Dom.text "Type of field"

				Form.selectInput
					name: 'type'
					title: "Type"
					options: 
						0: ["text", "Text field"]
						1: ["date", "Date picker"]
						2: ["number", "Numeric value"]
						3: ["url", "Web URL"]
					default: 0
					onChange: (v) !-> result[1] = v

			, (okay) ->
				addCallback result if okay
			, [false, 'Cancel', true, 'Add']

# Initial entree point
exports.render = !->
	if Page.state.get(0) is 'form' then return renderForm()
	if Page.state.get(0) is 'user' then return renderUser()
	return renderOverview()