attachmentTypes = 
    Ra:
        name: "Artillery"
        color: "red"
        order: 1
        description: "275mm howitzer"
    Rd:
        name: "Direct Fire"
        color: "red"
        order: 2
        description: "Gatling meson cannons"
    Rh:
        name: "Hand to Hand"
        color: "red"
        order: 3
        description: "Close combat gear"
    B:
        name: "Defense"
        color: "blue"
        order: 4
        description: "ECM package"
    Y:
        name: "Spotting"
        color: "yellow"
        order: 5
        description: "Laser designator"
    G:
        name: "Movement"
        color: "green"
        order: 6
        description: "Augemented mobility"
    W:
        name: ""
        color: "white"
        order: 7



class Die extends Backbone.Model
    color: -> @get('color') or 'white'
    value: -> @get('value') or no
    enabled: -> @get('enabled') isnt false
    d: -> @get('d') or 6
    
    roll: ->
        @set value: Math.ceil(Math.random() * @d())
    
class Dice extends Backbone.Collection
    model: Die
    comparator: (d) -> 1000-d.value()
    values: -> @map (d) ->d.value()

class Attachment extends Backbone.Model
    initialize: ->
        @dice = new Dice()

class Attachments extends Backbone.Collection
    model: Attachment
    comparator: (a) ->
        attachmentTypes[a.id].order
    
class Frame extends Backbone.Model
    moved: -> @get('moved') isnt false and @get('moved') isnt undefined
    
    initialize: ->
        @dice = new Dice
        @attachments = new Attachments  
        setup = @get('setup')
        setup['W']=[2]
        for type, [d6Count, d8Count, desc] of @get('setup')
            typeInfo = attachmentTypes[type]
            continue unless typeInfo?
            desc = false if desc is undefined or desc is ''
            attachment = new Attachment
                id: type
                name: typeInfo['name']
                description: desc or typeInfo.description
            if d6Count > 0
                for i in [1..d6Count]
                        die = new Die( {color: typeInfo['color']} )
                        @dice.add die
                        attachment.dice.add die
            if d8Count > 0
                for i in [1..d8Count]
                        die = new Die( {color: typeInfo['color'], d:8 } )
                        @dice.add die
                        attachment.dice.add die
            @attachments.add attachment
    
    addAttachment: (type, settings)->
        [numDie, description] = settings
    
    endTurn: ->
        @dice.each (d)->d.set value: undefined
        @set rolled: false, moved: false
    
    roll: ->
        @dice.each (die)->die.roll()
        @set rolled:true
    
    toggleMoved: ->
        @set moved: not @moved()

class Frames extends Backbone.Collection
    model: Frame
    
# ---

class FrameCardView extends Backbone.View
    tagName: 'div'
    
    events:
        'click' : 'click'
    
    initialize: ->
        @model.on 'change', @render
        @model.on 'remove', => @remove()
        @model.on 'destroy', => @remove()
        
    click: =>
        if not @model.get('rolled')
            @model.roll()
        else
            @model.toggleMoved()
        return false
        
    
    render: =>
        $card = $('<div>').attr('class','card card-frame')
        $(@el).addClass('span3').html('').append($card)
        $card.append($('<h1>').text(@model.get 'name')).addClass("team-#{@model.get('team')}")
        $card.find('h1').css({'font-size':'25px'}) if @model.get('name').length > 13
        $card.find('h1').css({'font-size':'17px'}) if @model.get('name').length > 16
        if @model.moved()
            $card.addClass('moved')
        $attachments = $('<div class="attachments">').appendTo($card)
        @model.attachments.each (attachment) ->
            $attachment = $('<div class="attachment">').html('
                <div class="dice"></div>
                <h3></h3>
                <p>&nbsp;</p>
            ').appendTo($attachments)
            $attachment.find('h3').text(attachment.get('name'))
            $attachment.find('p').text(attachment.get('description')) unless attachment.get('description') is ''
            attachment.dice.sort({silent:true})
            for die in attachment.dice.models
                new DieView({model:die}).render().$el.appendTo($attachment.find('.dice'))
        return @

class DieView extends Backbone.View
    tagName: 'i'
    events:
        'click':'toggle'
    initialize: ->
        @model.on 'change', @render
    toggle: (evt)=>
        @model.set 'enabled': not @model.enabled()
        return false
    render: =>
        $(@el)
        .attr('class',"die #{@model.get('color')} d#{@model.d()}")
        .html($('<div>').append($('<span>').text(@model.get('value') or '')))
        if not @model.get('value')?
            @$el.addClass('unrolled')
        if @model.enabled() is false
            @$el.addClass('disabled').find('span').text("X")
        return @

allFrames = new(Frames)
allFrames.on 'add', (model)->
    view = new FrameCardView({model:model})
    $('#frameCards').append(view.render().el)
    
$('#endTurn').on 'click', ->
    allFrames.each (f)->f.endTurn()
    
    
# The edit page stuff should be refactored into a backbone view and model
$('#editFrames').on 'click', ->
    $('#frameCards').toggle()
    $('#frameSetup').toggle()
$('#save').on 'click', ->
    loadFromSetup()
    $('#gettingStarted').remove()
    $('#frameCards').toggle()
    $('#frameSetup').toggle()

loadFromSetup = ->
    allFrames.each (x)->x.trigger('remove')
    allFrames.reset()
    
    DICE_REGEX = /[dD]([68])([A-Za-z]{1,2})/
    TRIM_REGEX = /[ \t](.+)[ \t]/
    for color in ['red','green','blue']
        framesText = $('#frameSetup [name='+color+']').val()
        for line in framesText.split("\n") when line.indexOf(':')>0
            [name,attachments] = line.split(':')
            continue unless name?
            frameAttachments = {}
            for fragment in attachments.split(' ')
                if match = DICE_REGEX.exec(fragment)
                    [all,die,type] = match
                    frameAttachments[type] ||= [0,0,'']
                    if die is "6"
                        frameAttachments[type][0]+=1
                    if die is "8"
                        frameAttachments[type][1]+=1
                else 
                    continue unless frameAttachments[type]?
                    text = fragment.replace(TRIM_REGEX,'$1').replace('(','').replace(')','')
                    continue unless text isnt ''
                    frameAttachments[type][2] += text+' '
            allFrames.add {name: name, team: color, setup: frameAttachments}

loadFromSetup()

window.allFrames = allFrames