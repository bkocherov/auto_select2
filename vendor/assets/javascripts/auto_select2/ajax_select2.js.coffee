jQuery ($) ->
  itemResultCssClass = (item)->
    cssClass = ''
    if item.class_name != undefined
      cssClass = item.class_name
    cssClass

  itemSelectionCssClass = (item)->
    cssClass = ''
    if item != null && item.selection_class_name != undefined
      cssClass = item.selection_class_name
    else if item != null
      cssClass = itemResultCssClass(item)
    cssClass

  formatResult = (item)->
    result = item.text
    if item.class_name != undefined
      classes = item.class_name.split(' ')
      classes = classes.map (origClass)->
        'in-' + origClass
      result = '<span class="'+classes.join(' ')+'">'+item.text+'</span>'
    result

  formatSelection = (item)->
    result = item.text
    classes = item.selection_class_name
    if classes == undefined
      classes = item.class_name
    if classes != undefined
      classes = classes.split(' ')
#      INFO: Turn on this if formatSelectionCssClass enabled
#      classes = classes.map (origClass)->
#        'in-' + origClass
      result = '<span class="'+classes.join(' ')+'">'+item.text+'</span>'
    result

  window.initAutoAjaxSelect2 = ->
    $inputs = $('input.auto-ajax-select2').not('.select2-offscreen')
    $inputs.each ->
      $input = $(this)
      path = $input.data('s2-href')
      limit = $input.data('s2-limit') || 25
      customFormatSelection = $input.data('s2-format-selection')
      customFormatResult = $input.data('s2-format-result')
      if customFormatSelection isnt `undefined` && (window[customFormatSelection] isnt `undefined`)
        formatSelectionFunc = window[customFormatSelection]
      else
        formatSelectionFunc = formatSelection
      if (customFormatResult isnt `undefined`) && (window[customFormatResult] isnt `undefined`)
        formatResultFunc = window[customFormatResult]
      else
        formatResultFunc = formatResult
      s2DefaultOptions = {
        allowClear: true
        multiple: false
        formatSelection: formatSelectionFunc
        formatResult: formatResultFunc
#        INFO: Not documented feature of select2 library, worked very well, but not clearing classes after item removing
#        formatSelectionCssClass: itemSelectionCssClass
        formatResultCssClass: itemResultCssClass
        ajax: {
          url: path,
          dataType: 'json',
          data: (term, page) ->
            ajaxData = { term: term, page: page }
            $this = $(this.context)

            additionalUserData = $this.data('s2-options')
            paramsCollection = {}
            if additionalUserData isnt `undefined`
              additionalAjaxData = additionalUserData['additional_ajax_data']
              if additionalAjaxData isnt `undefined`
                $(additionalAjaxData['selector']).each (index, el) ->
                  $el = $(el)
                  paramsCollection[$el.attr('name')] = $el.val()
                  return
                $.extend(paramsCollection, additionalAjaxData['params'])
                delete paramsCollection[$this.attr('name')]

            return $.extend({}, paramsCollection, ajaxData)
          ,
          results: (data, page) ->
            more = (page * limit) < data.total
            if data.total == 1 and not $input.data('s2-clearing') and not $input.select2("val")
              $input.select2("val", data.items[0].id)
            $input.data('s2-clearing', false)
            return { results: data.items, more: more }
        },
        initSelection : (element, callback) ->
          $element = $(element)
          id = $element.val()
          initText = $element.data('init-text')
          initClassName = $element.data('init-class-name')
          initSelectionClassName = $element.data('init-selection-class-name')
          if (id != '')
            if initText != undefined
              params = { id: id, text: initText }
              if initClassName != undefined
                params.class_name = initClassName
                params.selection_class_name = initSelectionClassName
              callback(params)
            else
              $.ajax(path, {
                data: { init: true, item_ids: id },
                dataType: "json"
              }).done((data) ->
                if(data != null)
                  callback(data)
                else
                  $element.val('')
                  callback({ id: '', text: '' })
              )
      }

      s2UserOptions = $input.data("s2-options")

      if s2UserOptions is `undefined`
        s2FullOptions = $.extend({}, s2DefaultOptions)
      else
        s2FullOptions = $.extend({}, s2DefaultOptions, s2UserOptions)

      $input.select2(s2FullOptions)
        .on "change", (e) ->
          $inputs.each ->
            $in = $(this)
            if $in != $input and $in.select2("val") == ''
              $in.select2("search", "").select2("close")

        .on "select2-clearing", (e) ->
          $(e.target).data("s2-clearing", true)

      return
    return
  initAutoAjaxSelect2()

  $body = $('body')

  $body.on 'cocoon:after-insert', ->
    initAutoAjaxSelect2()
    return
  return
