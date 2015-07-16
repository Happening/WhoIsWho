Db = require 'db'
Dom = require 'dom'
Form = require 'form'
Icon = require 'icon'
Modal = require 'modal'
Obs = require 'obs'
Page = require 'page'
Plugin = require 'plugin'
Server = require 'server'
Ui = require 'ui'
{tr} = require 'i18n'
renderUser = require 'renderUser'

# Initial entry point
exports.render = !->
	if arg = Page.state.get(0)
		if arg is 'form' then return renderUser.renderForm(Plugin.userId()) else renderUser.renderUser(arg)
	else
		return renderOverview()

#Settings view.
exports.renderSettings = !->
	#default options
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
					Dom.onTap !->
						checked = !checkE.prop('checked')
						checkE.prop 'checked', checked
						handleChange 
							value: checked
							longText: opts.text
							type: opts.sub

				if opts.trash
					Icon.render(data: 'trash')
					Dom.onTap !->
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