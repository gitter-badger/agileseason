$(document).on 'page:change', ->
  return unless document.body.id == 'issues_show'
  console.log 'issue:load'

  $(document).keyup (e) ->
    if (e.keyCode == 27) # esc
      Turbolinks.visit($('.b-menu .boards a').attr('href'))

  $('pre code').each (i, block) ->
    hljs.highlightBlock block

  init_uploading()

  $('.move-to-column li').click ->
    $('.move-to-column li').removeClass 'active'
    $(@).addClass 'active'

  $('.b-issue-modal').click (e) ->
    unless $(e.target).is('.editable-form.active textarea, .editable-form.active .save, .preview, .attach-images, controls, .upload, .upload input, .write')
      if $('.add-comment-form').hasClass 'active'
        $('textarea', '.add-comment-form.active').val('')
      close_active_form()

  $('textarea', '.add-comment-form').click (e) ->
    $form = $(@).closest('.add-comment-form')
    $form.addClass 'active'
    $('textarea', $form).focus()
    e.stopPropagation()

  $('.editable').click (e) ->
    if $(e.target).is(':checkbox')
      return

    unless $(@).closest('.add-comment-form').length > 0
      open_form($(@))

  $('.preview').click ->
    string = $('textarea', $(@).closest('form')).val()

    $.post $(@).data('url'), string: string, (markdown) =>
      $(@).closest('form').addClass('preview-mode')
      $('.preview-textarea', $(@).closest('form')).html(markdown)

  $('.write').click ->
    $(@).closest('form').removeClass('preview-mode')

  $('.editable-form').click (e) ->
    if $(e.target).is('.add-comment-form.active .save')
      $form = $(@).closest '.editable-form'
      url = $form.data('url')
      new_content = $('textarea', '.editable-form.active').val()

      $('textarea', '.editable-form.active').val('')

      $current_issue = $('.current-issue')

      #unless new_content == ''
        #$('.issue-comments').append('<div class="b-preloader"></div>')
        #$.get url, body: new_content, ->
          #$('.octicon-comment-discussion', $current_issue).addClass 'show'
          #load_comments()

      close_active_form()


    else if $(e.target).is('.editable-form.active .save')
      $(@).trigger('form:save')


  $('.editable-form').on 'form:save', ->
    #console.log 'form:save'

    $form = $(@)
    $editable_node = $(@).prev()
    $current_issue = $('.current-issue') # миниатюра открытого тикета

    url = $form.prev().data('url')
    new_content = $('textarea', '.editable-form.active').val()

    # issue name save
    if $(@).prev().hasClass 'issue-name'
      $editable_node.html(new_content)
      #console.log 'title:submit'
      $('.issue-name', $current_issue).html(new_content)

      $.get url, title: new_content
      close_active_form()

    # description save
    else if $(@).prev().hasClass 'description'
      if new_content == ''
        $editable_node.html('Description').addClass 'blank-description'
        $('.octicon-book', $current_issue).hide()

      else
        update_initial_data($(@), new_content)
        $.post $('.preview', @).data('url'), string: new_content, (markdown) ->
          $editable_node.html(markdown).removeClass 'blank-description'
        $('.octicon-book', $current_issue).show()

      $.get url, body: new_content
      close_active_form()

    # save a new comment
    else if $(@).prev().hasClass 'add-comment'
      unless new_content == ''
        $('.issue-comments').append('<div class="b-preloader horizontal"></div>')
        $.get url, body: new_content, ->
          $('.octicon-comment-discussion', $current_issue).addClass 'show'
          load_comments()

      close_active_form()

  $('.issue-description').on 'click', '.task', (e) ->
    update_by_checkbox($(@), '.description')



  $('.delete').click ->
    if window.confirm('Delete comment?')
      $.get $(@).data('url')
      $(@).closest('.issue-comment').remove()

  $('.edit', @).click ->
    open_form($(@).closest('.controls').next())
    $('.editable-form', $(@).closest('.comment-body')).trigger 'comment_form:load'

  $('.editable-form').on 'comment_form:load', ->
    #console.log 'comment_form:load'

  $('.editable-form', '.issue-comments').click (e) ->
    if $(e.target).is('.editable-form.active .save')
      $(@).trigger('comment:save')

    $('.editable-form', '.issue-comments').on 'comment:save', ->
      $form = $(@)
      $editable_node = $(@).prev()
      $current_issue = $('.current-issue') # миниатюра открытого тикета

      url = $form.prev().data('url')
      delete_url = $form.prev().data('delete')
      new_content = $('textarea', '.editable-form.active').val()

      if new_content.replace(/\s*\n*/g, '') == ''
        close_active_form()

      else
        update_initial_data($(@), new_content)
        $.get url, body: new_content
        $.post $('.preview', @).data('url'), string: new_content, (markdown) ->
          $editable_node.html(markdown)
          close_active_form()

    $('.issue-comments').on 'click', '.task', (e) ->
      update_by_checkbox($(@), '.comment')


    #console.log 'modal ajax:success'
    #number = $(@).find('.b-issue-modal').data('number')
    ## FIX : Find reason what find return two element .b-assignee-container
    #find_issue(number).find('.b-assignee-container').each ->
      #$(@).html(data)
    #$(@).find('.b-assignee-container').html(data)
    #$(@).find('.b-assign .check').removeClass('octicon octicon-check')
    #$('.check', $(e.target)).addClass('octicon octicon-check')
    #$(@).find('.popup').hide() # скрытый эффект - закрывает все popup


  # раскрыть попап с календарем для установки крайней даты
  $('.set-due-date').click ->
    $popup = $(@).parent().find('.popup')
    $datepicker = $('.datepicker', $popup)
    $datepicker.datepicker({
      dateFormat: 'dd/mm/yyyy',
      onSelect: ->
        $popup.find('.date input').val($(@).val())
    })
    $datepicker.datepicker('setDate', new Date($(@).data('date')))
    $popup.show()

  # сохранение крайней даты
  $('.edit-due-date .button.save').click ->
    $modal = $(@).parents('.issue-modal')
    date = $modal.find('.date input').val()
    time = $modal.find('.time input').val()
    $.ajax
      url: $modal.find('.edit-due-date').data('url'),
      data: { due_date: "#{date} #{time}" },
      success: (date) ->
        $('.popup').hide()
        $('.due-date').removeClass('none').html(date)
        # FIX : Extract method for find current issue number
        #number = $modal.find('.b-issue-modal').data('number')
        # FIX : Find reason what find return two element .due-date
        #find_issue(number).find('.due-date').each ->
          #$(@).removeClass('none').html(date)

  # раскрыть попап с пользователями для назначения
  $('.assignee').click ->
    $(@).parent().find('.popup').show()

  # скрыть попап с пользователями для назначения
  $('.close-popup').click ->
    $popup = $(@).closest('.popup')
    $popup.parent().find('.assignee').show()
    $popup.hide()


  $('.b-assign .user').click (e) ->
    #debugger
    $.ajax ->
      url: $(@).attr('href')
      success: (data)->
        $('.user-list').html(data).show()
    e.preventDefault()

  # раскрыть попап с лейблами тикета
  $('.add-label').click ->
    $(@).parent().prev().show()
    $(@).hide()

  # скрыть попап с лейблами тикета
  $('.close-popup').click ->
    $(@).closest('.popup').next().find('.add-label').show()
    $(@).closest('.popup').hide()

  # изменить набор лейблов тикета
  $('label input').on 'change', ->
    labels = []
    html_labels = []
    $(@).parents('.labels-block').find('input:checked').each ->
      labels.push $(@).val()
      html_labels.push('<div class="label" style="' + $(@).parent().attr('style') + '">' + $(@).val() + '</div>')

    # обновить текущий список лейблов тикета на борде и в попапе
    $('.b-issue-labels').html(html_labels)

    # отправить на сервер набор лейблов
    $.get $(@).data('url'), { labels: labels }




init_uploading = ->
  url = $('.board').data('direct_post_url')
  form_data = $('.board').data('direct_post_form_data')
  window.init_direct_upload($('.directUpload').find('input:file'), url, form_data)

find_issue = (number) ->
  $(".issue[data-number='#{number}']")

open_form = ($editable_node) ->
  #console.log 'open form'
  setTimeout ->
      if $editable_node.data('initial')
        initial_data = $editable_node.data('initial').toString().trim()
      else
        initial_data = ''

      $editable_node
        .hide()
        .next().show().addClass('active')
        .find('textarea').focus().val(initial_data)
    , 300

close_active_form = ->
  #console.log 'close active form'
  if $('.editable-form.active').length > 0
    $('.editable-form.active').val('')
    $('.editable-form.active')
      .hide()
      .removeClass('active')
      .prev().show()

update_by_checkbox = ($checkbox, container_selector) ->
  event.stopPropagation()
  $container = $checkbox.parents(container_selector)
  checkbox_index = $checkbox.index("#{container_selector} .task")
  checkbox_value = $checkbox.is(':checked')
  initial_body = $container.data('initial')
  new_body = replaceNthMatch(initial_body, /(\[(?:x|\s)\])/, checkbox_index + 1, if checkbox_value then '[x]' else '[ ]')

  $.get($container.data('url'), body: new_body)
  update_initial_data($container, new_body)

update_initial_data = ($element, new_content) ->
  if $element.attr('data-initial')
    $element.data('initial', new_content)
  else
    $element.parent().find('[data-initial]').data('initial', new_content)
