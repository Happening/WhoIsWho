Db = require 'db'
Dom = require 'dom'
Form = require 'form'
Icon = require 'icon'
Modal = require 'modal'
Obs = require 'obs'
Page = require 'page'
Photo = require 'photo'
Photoview = require 'photoview'
Plugin = require 'plugin'
Server = require 'server'
Ui = require 'ui'
{tr} = require 'i18n'

Event = require 'event'
Datepicker = require 'datepicker'
# BigImg = require 'bigImg'

renderHeader = (id) ->
	Dom.div !->
		Dom.style
			Box: 'middle center'
			background: '#fff'
		key = Plugin.userAvatar(id)
		if !key || key[0]=='#'
			color = (key || '#ccc')
			data = 'silhouette'
		else
			data = Photo.url key, 200
		Dom.div !->
			Dom.style
				width: '200px'
				height: '200px'
				margin: '20px'
			Ui.avatar key,
				size: 200
			Dom.div !->
				Dom.style
					Box: 'bottom center'
					position: 'absolute'
					top: '22px'
					height: '200px'
					width: '200px'
					background: 'linear-gradient(to top, rgba(0,0,0,0.55) 0%,rgba(0,0,0,0) 50%)'
					borderRadius: '50%'
					padding: '20px'
					boxSizing: 'border-box'
					fontSize: '125%'
					color: '#fff'
				Dom.div !->
					Dom.style
						textAlign: 'center'
					Dom.text Form.smileyToEmoji Plugin.userName(id)
					Icon.render(data: 'info', color: '#fff', style: marginLeft: '10px')
			Dom.onTap !->
				Plugin.userInfo id

renderPhoto = (key, title, trashId) ->
	Page.nav !->
		Page.setTitle title
		if trashId 
			Page.setActions
				icon: 'trash'
				label: 'remove photo'
				action: !->
					Modal.confirm null, "Remove photo?", !->
						Server.sync 'removePhoto', trashId, !->
					Page.back()
		Dom.style
			padding: '0px'
			backgroundColor: '#333'
		Photoview.render
			key: key

getUploading = (id, photoKey) ->
	if uploads = Photo.uploads.get()
		for key, upload of uploads
			return upload if upload.localId is id + photoKey

addField = (id, key, field, input, sep = true) !->
	userValue = null
	if !field.value then return
	if !input
		userValue = Db.shared.get(id, key)
		if !userValue? then return

	if sep then Form.sep()
	Dom.div !->
		Dom.p !->
			Dom.style margin: '10px 0px 10px 10px'
			Dom.text Form.smileyToEmoji field.longText
		Dom.p !->
			Dom.style
				margin: '0px 10px 10px 0px'
				textAlign: 'right'
				clear: 'both'
				fontSize: '21px'
			if input
				if field.type is 'date'
					Form.box !->
						today = 0|(((new Date()).getTime() - (new Date()).getTimezoneOffset()*6e4) / 864e5)
						# select date
						curDate = Db.shared.get(Plugin.userId(), key)||today
						# curDate = today
						[handleChange] = Form.makeInput
							name: key
							value: curDate
							content: (value) !->
								Dom.div !->
									Dom.style fontSize: '100%'
									Dom.text Datepicker.dayToString(value)

						Icon.render data: 'edit'
						Dom.onTap !->
							val = curDate
							Modal.confirm tr("Select date"), !->
								Datepicker.date
									value: val
									onChange: (v) !->
										val = v
							, !->
								handleChange val
								curDate = val
				else if field.type is 'photo'
					Form.box !->
						photo = null
						upload = getUploading(id, key)
						dbPhoto = Db.shared.get(id, key)
						if upload? 
							photo = upload.thumb
						if dbPhoto?
							photo = Photo.url(dbPhoto.key, 400 )					
						if photo
							Dom.div !->
								Dom.style
									background: "url(#{photo}) 50% 50% no-repeat"
									backgroundSize: 'cover'
									width: '100%'
									height: Page.width()/2
									verticalAlign: 'bottom'
									Box: 'inline right bottom'
								if upload?
									Ui.spinner 24, !->
										Dom.style margin: '5px'
									, 'spin-light.png'
						else
							Dom.style color: '#aaa'
							Dom.text tr("< Add Image >")
						Icon.render (data: 'camera')
						Dom.onTap !->
							if photo
								renderPhoto photo.key, field.longText, key
							else
								Photo.pick 'camera', [key], id+key
				else
					Form.input
						name: key
						text: field.longText
						value: Db.shared.get(id, key)
						onSave: (val) !->
							d = {}
							d[key] = val
							Server.sync "saveInfo", d, !->
								Db.shared.set id, d
			else #not input
				if field.type is 'date'
					Dom.text Datepicker.dayToString(0|userValue)
				else if field.type is 'photo'
					Dom.style marginLeft: '10px'

					Dom.div !->
						size = Math.max Page.width()-16, Page.height()-100
						Dom.style
							background: "url(#{Photo.url userValue.key, size}) 50% 50% no-repeat"
							backgroundSize: 'cover'
							width: '100%'
							height: Page.width()/2
						Dom.onTap !->
							renderPhoto userValue.key, field.longText
				else
					Dom.userText Form.smileyToEmoji userValue

renderUser = (id)->
	Page.setTitle Plugin.userName(id)
	Dom.style padding: '0px'

	#header img
	renderHeader id

	#content
	Dom.section !->
		Obs.observe !->
			empty = !Db.shared.get(id)?
			if empty
				Dom.userText Form.smileyToEmoji( tr("User has not filled in any information yet :("))
				return
		if Db.shared.peek(id, 'primary')?
			empty = false
			addField(id, 'primary', {longText: Db.shared.get('fields', 'primary'), value: true}, false, false)

		([k,v] for k,v of Db.shared.get('fields')).forEach ([key, field]) !-> #forEach hack
			if key isnt 'primary'
				addField(id, key, field, false)

		([k,v] for k,v of Db.shared.get('custom')).forEach ([key, field]) !-> #forEach hack
			empty = false
			addField(id, key, field, false)

		

renderForm = (id) ->
	Page.setTitle Plugin.userName(id)
	Dom.style padding: '0px'
	#header img
	renderHeader id

	# content
	Dom.section !->
		addField(id, 'primary', {longText: Db.shared.get('fields', 'primary'), value: true}, true, false)

		([k,v] for k,v of Db.shared.get('fields')).forEach ([key, field]) !-> #forEach hack
			if key isnt 'primary'
				addField(id, key, field, true)

		([k,v] for k,v of Db.shared.get('custom')).forEach ([key, field]) !->
			addField(id, key, field, true)

	Form.setPageSubmit (value) !->
		Server.sync 'saveInfo', value, !->
			Db.shared.set(Plugin.userId(), value)
		Page.back()
	, 0

renderOverview = ->
	#Urge the user to enter his own details
	if not Db.shared.peek(Plugin.userId(), 'primary')?
		Page.setFooter
			label: tr("Edit your info")
			action: !->
				Page.nav ['form']   

	#Render overview of all users
	Dom.style textAlign: 'center'
	size = (Page.width()-16) / Math.floor((Page.width()-0)/100)
	Plugin.users.observeEach (user) !->
		Dom.div !->
			Dom.style
				display: 'inline-block'
				position: 'relative'
				padding: '8px'
				boxSizing: 'border-box'
				borderRadius: '2px'
				width: size+'px'

			Ui.avatar Plugin.userAvatar(user.key()),
				size: size-16
				style:
					display: 'inline-block'
					margin: '0 0 1px 0'

			Dom.div !->
				Dom.style fontSize: '18px'
				Dom.text Form.smileyToEmoji user.get('name')
			Dom.div !->
				Dom.style
					width: '100%'
					overflow: 'hidden'
					whiteSpace: 'nowrap'
					textOverflow: 'ellipsis'
					textAlign: 'center'
					fontSize: '14px'
				Dom.userText Form.smileyToEmoji Db.shared.get(user.key(), 'primary') ? "\n"
			Dom.onTap !->
				if parseInt(user.key()) is Plugin.userId()
					Page.nav ['form'] #edit yourself
				else 
					Page.nav {0:user.key()} #view other user's details  
			
#Settings view.
exports.renderSettings = !->
	fieldsOptions = 
		'name':
			longText: tr("Name")
			type: 'text'
			value: false
		'function':
			longText: tr("Function or profession")
			type: 'text'
			value: false
		'email':
			longText: tr("Email address")
			type: 'email'
			value: false
		'telephone':
			longText: tr("Telephone number")
			type: 'tel'
			value: false
		'birthday':
			longText: tr("Birthday")
			type: 'date'
			value: false
		'address':
			longText: tr("Address")
			type: 'address'
			value: false

	#get fieldsOptions from the server if it's there.
	if Db.shared?.get('fields')?
		fieldsOptions = Db.shared.get('fields')

	Dom.h5 tr("Change the information users can provide")

	Dom.h3 tr("Primary field")
	Form.input
		name: "primary"
		text: tr("Describe yourself briefly")
		value: Db.shared?.get('fields', 'primary')

	Dom.h3 !->
		Dom.style marginTop: '20px'
		Dom.text tr("Other fields")

	fieldsO = Obs.create(fieldsOptions)

	#An input element that holds a hash as value.
	#Next to that, in implements a checkbox with some custom options.
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
						Modal.confirm tr("Are you sure you want to remove ") + orgValue.longText + "?", !->
							handleChange 
								value: 'delete'
							divE.style display: 'none'

			if opts.sep is 'bottom'
				Form.sep()


	#Add default fields
	fieldsO.iterate (f) !->
		if f.key() isnt 'primary'
			makeComplexCheck
				text: f.get('longText')
				name: f.key()
				check: true
				value: 
					value: Db.shared?.get('fields', f.key(), 'value') ? true
					longText: f.get('longText')
					type: f.get('type')
			Form.sep()

	#custom fields
	customO = Obs.create if Db.shared?.peek('custom') then Db.shared?.peek('custom') else {}
	maxCustoms = if Db.shared?.peek('customId') then Db.shared?.peek('customId') else 0
	# maxCustoms = 0
	customIdH = Form.hidden('cId', maxCustoms)

	customO.iterate (c) !->
		makeComplexCheck
			text: c.get('longText')
			name: c.key()
			check: false
			trash: true
			sep: 'bottom'
			value: 
				longText: c.get('longText')
				type: c.get('type')

	#Add field
	Dom.div !->
		Dom.style
			padding: '12px 8px'
			color: Plugin.colors().highlight
		Dom.text tr "+ Custom field"
		
		addCallback = (value) !->
			++maxCustoms
			customO.set ('custom' + maxCustoms), {'longText': value[0], 'type': value[1], value:true}
			customIdH.value(maxCustoms)
		Dom.onTap !->
			result = []
			title = tr("Custom field")
			Modal.show title, !->
				Form.input
					text: tr("Name your custom field")
					onChange: (v) !-> result[0] = v
				Form.selectInput
					name: 'type'
					title: tr("Type of field")
					options: 
						0: ["text", tr("Text field")]
						1: ["date", tr("Date picker")]
						2: ["photo", tr("Photo")]
						3: ["url", tr("Web URL")]
					default: 0
					onChange: (v) !-> result[1] = v

			, (okay) ->
				addCallback result if okay
			, [false, tr("Cancel"), true, tr( "Add")]

# Initial entry point
exports.render = !->
	if arg = Page.state.get(0)
		if arg is 'form' then return renderForm(Plugin.userId()) else renderUser(arg)
	else
		return renderOverview()