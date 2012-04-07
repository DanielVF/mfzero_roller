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

class Attachment extends Backbone.Model
    initialize: ->
        @dice = new Dice()

class Attachments extends Backbone.Collection
    model: Attachment
    comparator: (a) ->
        attachmentTypes[a.id].order
    
class Frame extends Backbone.Model
    initialize: ->
        @dice = new Dice
        @attachments = new Attachments  
        setup = @get('setup')
        setup['W']=[2]
        for type, [dieCount, desc] of @get('setup')
            typeInfo = attachmentTypes[type]
            attachment = new Attachment
                id: type
                name: typeInfo['name']
                description: desc or ''
            for i in [1..dieCount]
                    die = new Die( {color: typeInfo['color']} )
                    @dice.add die
                    attachment.dice.add die
            @attachments.add attachment
    
    addAttachment: (type, settings)->
        [numDie, description] = settings
    
    endTurn: ->
        @dice.each (d)->d.set value: undefined
        @set rolled: false
    
    roll: ->
        @dice.each (die)->die.roll()
        @set rolled:true

class Frames extends Backbone.Collection
    model: Frame
    
# ---

class FrameCardView extends Backbone.View
    tagName: 'div'
    
    events:
        'click' : 'roll'
    
    initialize: ->
        @model.on 'change', @render
        @model.on 'remove', => @remove()
        @model.on 'destroy', => @remove()
        
    roll: =>
        return if @model.get('rolled')
        @model.roll()
    
    render: =>
        $card = $('<div>').attr('class','').addClass('card');
        $(@el).addClass('span3').html('').append($card)
        $card.append($('<h1>').text(@model.get 'name')).addClass("team-#{@model.get('team')}")
        $attachments = $('<div class="attachments">').appendTo($card)
        @model.attachments.each (attachment) ->
            $attachment = $('<div class="attachment">').html('
                <div class="dice"></div>
                <h3></h3>
                <p></p>
            ').appendTo($attachments)
            $attachment.find('h3').text(attachment.get('name'))
            $attachment.find('p').text(attachment.get('description'))
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
        $(@el).attr('class',"die #{@model.get('color')}").text(@model.get('value') or '')
        if not @model.get('value')?
            @$el.addClass('unrolled')
        if @model.enabled() is false
            @$el.addClass('disabled').text("X")
        return @

allFrames = new(Frames)
allFrames.on 'add', (model)->
    view = new FrameCardView({model:model})
    $('#frameCards').append(view.render().el)
    
$('#endTurn').on 'click', ->
    allFrames.each (f)->f.endTurn()

allFrames.add
    name: "Col. Salt"
    team: "red"
    setup: 
        Rd: [2,'Long Range Pounders']
        B: [1,'Xenon Hardned Shield']
        G: [1,'Bi-fuel Jet Packs']
allFrames.add
    name: "Cpt. Ordanaro"
    team: "red"
    setup:
        Rd: [2,'Long Range Pounders']
        B: [1,'Composite Armour']
        Y: [1,'XT-77 Scope']
allFrames.add
    name: "Long Glasser"
    team: "green"
    setup:
        Ra: [1,"166mm Artillery Tube"]
        Y: [2,"Zeropoint Field Sensor"]
        B: [1, "Forcefield Module"]
allFrames.add
    name: "Scrambler #1"
    team: "green"
    setup:
        Rh: [2,"Kordavi Ranged Blades"]
        Y: [1,"Laser Designator"]
        B: [1, "Forcefield Module"]
allFrames.add
    name: "Scrambler #2"
    team: "green"
    setup:
        Rh: [2,"Kordavi Ranged Blades"]
        Y: [1,"Laser Designator"]
        B: [1, "Forcefield Module"]
allFrames.add
    name: "Scrambler #3"
    team: "green"
    setup:
        Rh: [2,"Kordavi Ranged Blades"]
        Y: [1,"Laser Designator"]
        B: [1, "Forcefield Module"]

window.allFrames = allFrames