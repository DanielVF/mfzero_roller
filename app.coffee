attachmentTypes = 
    Ra:
        name: "Artillery"
        color: "red"
        order: 1
    Rd:
        name: "Direct Fire"
        color: "red"
        order: 2
    Rh:
        name: "Hand to Hand"
        color: "red"
        order: 3
    B:
        name: "Defense"
        color: "blue"
        order: 4
    Y:
        name: "Spotting"
        color: "yellow"
        order: 5
    G:
        name: "Movement"
        color: "green"
        order: 6
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
            attachment = new Attachment
                id: type
                name: typeInfo['name']
                description: desc or ''
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
        if @model.moved()
            $card.addClass('moved')
        $attachments = $('<div class="attachments">').appendTo($card)
        @model.attachments.each (attachment) ->
            $attachment = $('<div class="attachment">').html('
                <div class="dice"></div>
                <h3></h3>
                <p></p>
            ').appendTo($attachments)
            $attachment.find('h3').text(attachment.get('name'))
            $attachment.find('p').text(attachment.get('description'))
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
    $('#frameCards').toggle()
    $('#frameSetup').toggle()

loadFromSetup = ->
    allFrames.each (x)->x.trigger('remove')
    allFrames.reset()
    ATTACHMENT_REGEX = /(1d8)?([0-9])?([A-Z][a-z]?)(\+1?d8)? ?(.+)/
    for color in ['red','green','blue']
        framesText = $('#frameSetup [name='+color+']').val()
        for line in framesText.split("\n") when line.indexOf(',')>0
            [name,attachmentTexts...] = line.split(',')
            frameAttachments = {}
            for text in attachmentTexts when match = ATTACHMENT_REGEX.exec(text)
                [all,alt8,d6s,type,d8s,desc] = match
                d8s = 1 if d8s isnt undefined
                d8s = 1 if alt8 isnt undefined
                frameAttachments[type] = [ d6s or 0 , d8s or 0 , desc]
            allFrames.add {name: name, team: color, setup: frameAttachments}

loadFromSetup()

window.allFrames = allFrames