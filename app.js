(function() {
  var Attachment, Attachments, Dice, Die, DieView, Frame, FrameCardView, Frames, allFrames, attachmentTypes, loadFromSetup,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  attachmentTypes = {
    Ra: {
      name: "Artillery",
      color: "red",
      order: 1
    },
    Rd: {
      name: "Direct Fire",
      color: "red",
      order: 2
    },
    Rh: {
      name: "Hand to Hand",
      color: "red",
      order: 3
    },
    B: {
      name: "Defense",
      color: "blue",
      order: 4
    },
    Y: {
      name: "Spotting",
      color: "yellow",
      order: 5
    },
    G: {
      name: "Movement",
      color: "green",
      order: 6
    },
    W: {
      name: "",
      color: "white",
      order: 7
    }
  };

  Die = (function(_super) {

    __extends(Die, _super);

    function Die() {
      Die.__super__.constructor.apply(this, arguments);
    }

    Die.prototype.color = function() {
      return this.get('color') || 'white';
    };

    Die.prototype.value = function() {
      return this.get('value') || false;
    };

    Die.prototype.enabled = function() {
      return this.get('enabled') !== false;
    };

    Die.prototype.d = function() {
      return this.get('d') || 6;
    };

    Die.prototype.roll = function() {
      return this.set({
        value: Math.ceil(Math.random() * this.d())
      });
    };

    return Die;

  })(Backbone.Model);

  Dice = (function(_super) {

    __extends(Dice, _super);

    function Dice() {
      Dice.__super__.constructor.apply(this, arguments);
    }

    Dice.prototype.model = Die;

    return Dice;

  })(Backbone.Collection);

  Attachment = (function(_super) {

    __extends(Attachment, _super);

    function Attachment() {
      Attachment.__super__.constructor.apply(this, arguments);
    }

    Attachment.prototype.initialize = function() {
      return this.dice = new Dice();
    };

    return Attachment;

  })(Backbone.Model);

  Attachments = (function(_super) {

    __extends(Attachments, _super);

    function Attachments() {
      Attachments.__super__.constructor.apply(this, arguments);
    }

    Attachments.prototype.model = Attachment;

    Attachments.prototype.comparator = function(a) {
      return attachmentTypes[a.id].order;
    };

    return Attachments;

  })(Backbone.Collection);

  Frame = (function(_super) {

    __extends(Frame, _super);

    function Frame() {
      Frame.__super__.constructor.apply(this, arguments);
    }

    Frame.prototype.moved = function() {
      return this.get('moved') !== false && this.get('moved') !== void 0;
    };

    Frame.prototype.initialize = function() {
      var attachment, desc, die, dieCount, i, setup, type, typeInfo, _ref, _ref2, _results;
      this.dice = new Dice;
      this.attachments = new Attachments;
      setup = this.get('setup');
      setup['W'] = [2];
      _ref = this.get('setup');
      _results = [];
      for (type in _ref) {
        _ref2 = _ref[type], dieCount = _ref2[0], desc = _ref2[1];
        typeInfo = attachmentTypes[type];
        attachment = new Attachment({
          id: type,
          name: typeInfo['name'],
          description: desc || ''
        });
        for (i = 1; 1 <= dieCount ? i <= dieCount : i >= dieCount; 1 <= dieCount ? i++ : i--) {
          die = new Die({
            color: typeInfo['color']
          });
          this.dice.add(die);
          attachment.dice.add(die);
        }
        _results.push(this.attachments.add(attachment));
      }
      return _results;
    };

    Frame.prototype.addAttachment = function(type, settings) {
      var description, numDie;
      return numDie = settings[0], description = settings[1], settings;
    };

    Frame.prototype.endTurn = function() {
      this.dice.each(function(d) {
        return d.set({
          value: void 0
        });
      });
      return this.set({
        rolled: false,
        moved: false
      });
    };

    Frame.prototype.roll = function() {
      this.dice.each(function(die) {
        return die.roll();
      });
      return this.set({
        rolled: true
      });
    };

    Frame.prototype.toggleMoved = function() {
      console.log('aaa');
      return this.set({
        moved: !this.moved()
      });
    };

    return Frame;

  })(Backbone.Model);

  Frames = (function(_super) {

    __extends(Frames, _super);

    function Frames() {
      Frames.__super__.constructor.apply(this, arguments);
    }

    Frames.prototype.model = Frame;

    return Frames;

  })(Backbone.Collection);

  FrameCardView = (function(_super) {

    __extends(FrameCardView, _super);

    function FrameCardView() {
      this.render = __bind(this.render, this);
      this.click = __bind(this.click, this);
      FrameCardView.__super__.constructor.apply(this, arguments);
    }

    FrameCardView.prototype.tagName = 'div';

    FrameCardView.prototype.events = {
      'click': 'click'
    };

    FrameCardView.prototype.initialize = function() {
      var _this = this;
      this.model.on('change', this.render);
      this.model.on('remove', function() {
        return _this.remove();
      });
      return this.model.on('destroy', function() {
        return _this.remove();
      });
    };

    FrameCardView.prototype.click = function() {
      if (!this.model.get('rolled')) {
        this.model.roll();
      } else {
        this.model.toggleMoved();
      }
      return false;
    };

    FrameCardView.prototype.render = function() {
      var $attachments, $card;
      $card = $('<div>').attr('class', 'card card-frame');
      $(this.el).addClass('span3').html('').append($card);
      $card.append($('<h1>').text(this.model.get('name'))).addClass("team-" + (this.model.get('team')));
      if (this.model.moved()) $card.addClass('moved');
      $attachments = $('<div class="attachments">').appendTo($card);
      this.model.attachments.each(function(attachment) {
        var $attachment, die, _i, _len, _ref, _results;
        $attachment = $('<div class="attachment">').html('\
                <div class="dice"></div>\
                <h3></h3>\
                <p></p>\
            ').appendTo($attachments);
        $attachment.find('h3').text(attachment.get('name'));
        $attachment.find('p').text(attachment.get('description'));
        _ref = attachment.dice.models;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          die = _ref[_i];
          _results.push(new DieView({
            model: die
          }).render().$el.appendTo($attachment.find('.dice')));
        }
        return _results;
      });
      return this;
    };

    return FrameCardView;

  })(Backbone.View);

  DieView = (function(_super) {

    __extends(DieView, _super);

    function DieView() {
      this.render = __bind(this.render, this);
      this.toggle = __bind(this.toggle, this);
      DieView.__super__.constructor.apply(this, arguments);
    }

    DieView.prototype.tagName = 'i';

    DieView.prototype.events = {
      'click': 'toggle'
    };

    DieView.prototype.initialize = function() {
      return this.model.on('change', this.render);
    };

    DieView.prototype.toggle = function(evt) {
      this.model.set({
        'enabled': !this.model.enabled()
      });
      return false;
    };

    DieView.prototype.render = function() {
      $(this.el).attr('class', "die " + (this.model.get('color'))).text(this.model.get('value') || '');
      if (!(this.model.get('value') != null)) this.$el.addClass('unrolled');
      if (this.model.enabled() === false) this.$el.addClass('disabled').text("X");
      return this;
    };

    return DieView;

  })(Backbone.View);

  allFrames = new Frames;

  allFrames.on('add', function(model) {
    var view;
    view = new FrameCardView({
      model: model
    });
    return $('#frameCards').append(view.render().el);
  });

  $('#endTurn').on('click', function() {
    return allFrames.each(function(f) {
      return f.endTurn();
    });
  });

  $('#editFrames').on('click', function() {
    $('#frameCards').toggle();
    return $('#frameSetup').toggle();
  });

  $('#save').on('click', function() {
    loadFromSetup();
    $('#frameCards').toggle();
    return $('#frameSetup').toggle();
  });

  loadFromSetup = function() {
    var ATTACHMENT_REGEX, all, attachmentTexts, color, desc, frameAttachments, framesText, line, match, name, number, text, type, _i, _len, _ref, _results;
    allFrames.each(function(x) {
      return x.trigger('remove');
    });
    allFrames.reset();
    ATTACHMENT_REGEX = /([0-9])?([A-Z][a-z]?) (.+)/;
    _ref = ['red', 'green', 'blue'];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      color = _ref[_i];
      framesText = $('#frameSetup [name=' + color + ']').val();
      _results.push((function() {
        var _j, _k, _len2, _len3, _ref2, _ref3, _results2;
        _ref2 = framesText.split("\n");
        _results2 = [];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          line = _ref2[_j];
          if (!(line.indexOf(',') > 0)) continue;
          _ref3 = line.split(','), name = _ref3[0], attachmentTexts = 2 <= _ref3.length ? __slice.call(_ref3, 1) : [];
          frameAttachments = {};
          for (_k = 0, _len3 = attachmentTexts.length; _k < _len3; _k++) {
            text = attachmentTexts[_k];
            if (!(match = ATTACHMENT_REGEX.exec(text))) continue;
            all = match[0], number = match[1], type = match[2], desc = match[3];
            frameAttachments[type] = [number, desc];
          }
          _results2.push(allFrames.add({
            name: name,
            team: color,
            setup: frameAttachments
          }));
        }
        return _results2;
      })());
    }
    return _results;
  };

  loadFromSetup();

  window.allFrames = allFrames;

}).call(this);
