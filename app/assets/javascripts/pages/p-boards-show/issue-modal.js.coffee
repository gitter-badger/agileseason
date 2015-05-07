$(document).on 'page:change', ->
  return unless document.body.id == 'boards_show'

################################################################################
    # issue modal loaded
################################################################################
  $('.issue-modal').on 'modal:load', ->
    return unless document.body.id == 'boards_show'
    console.log 'modal:load'

    $current_issue = $('.issue[data-number="' + $(@).closest('.b-issue-modal').data('number') + '"]') # миниатюра открытого тикета
    $issue_modal = $('.issue-modal')

    load_comments()

    $('.b-issue-modal').click (e) ->
      unless $(e.target).is('.editable-form.active textarea, .editable-form.active .save, .preview, .attach-images, controls')
        close_active_form()

    $('.editable').click ->
      if $(@).hasClass 'add-comment'
        open_new_comment_form($(@))
      else
        open_form($(@))

    $('.editable-form').click (e) ->
      if $(e.target).is('.editable-form.active .save')
        $(@).trigger('form:save')

    $('.editable-form').on 'form:save', ->
      console.log 'form:save'

      $form = $(@)
      $editable_node = $(@).prev()
      $current_issue = $('.current-issue') # миниатюра открытого тикета

      url = $form.prev().data('url')
      new_content = $('textarea', '.editable-form.active').val()

      # issue name save
      if $(@).prev().hasClass 'issue-name'
        $editable_node.html(new_content)
        console.log 'title:submit'
        $('.issue-name', $current_issue).html(new_content)

        $.get url, title: new_content, -> console.log 'save title'
        close_active_form()

      # description save
      else if $(@).prev().hasClass 'description'
        if new_content == ''
          $editable_node.html('Description').addClass 'blank-description'
          $('.octicon-book', $current_issue).hide()

        else
          $editable_node.html(new_content).removeClass 'blank-description'
          $('.octicon-book', $current_issue).show()

        $.get url, body: new_content
        close_active_form()

      # save a new comment
      else if $(@).prev().hasClass 'add-comment'
        unless new_content == ''
          $.get url, comment: new_content, -> $('.octicon-comment-discussion', $current_issue).addClass 'show'
          load_comments()

        close_active_form()

    ################################################################################
    # comments are loaded in issue modal
    ################################################################################
    $('.issue-comments').on 'comments:load', ->
      console.log 'comments:load'

      $('.delete', @).click ->
        if window.confirm('Delete comment?')
          $.get $(@).data('url'), {}, ->
            if $('.comment', $issue_modal).length < 1
              $('.octicon-comment-discussion', $current_issue).removeClass 'show'

          $(@).closest('.issue-comment').remove()

      $('.edit', @).click ->
        console.log 'edit:click'
        open_form($(@).closest('.controls').next())
        $('.editable-form', $(@).closest('.comment-body')).trigger 'comment_form:load'

      $('.editable-form').on 'comment_form:load', ->
        console.log 'comment_form:load'

        $('.editable-form', '.issue-comments').click (e) ->
          if $(e.target).is('.editable-form.active .save')
            $(@).trigger('comment:save')

      $('.editable-form', '.issue-comments').on 'comment:save', ->
        console.log 'comment:save'
        $form = $(@)
        $editable_node = $(@).prev()
        $current_issue = $('.current-issue') # миниатюра открытого тикета

        url = $form.prev().data('url')
        delete_url = $form.prev().data('delete')
        new_content = $('textarea', '.editable-form.active').val()

        if new_content.replace(/\s*\n*/g, '') == ''
          close_active_form()

        else
          $.get url, comment: new_content, -> console.log 'comment saved'
          $editable_node.html(new_content)
          close_active_form()

    ################################################################################
    # move-to events in issue modal
    ################################################################################
    $('.move-to-column li', $issue_modal).each ->
      $(@).addClass('active') if $(@).data('column') == $current_issue.closest('.board-column').data('column')

    # Перемещение тикета в попапе
    $('.move-to-column li', $issue_modal).click ->
      $current_issue = $('.current-issue') # миниатюра открытого тикета
      return if $(@).hasClass 'active'

      issue = $current_issue.data('number')
      column = $(@).data('column')
      board = $('.board').data('github_full_name')

      $col_1 = $current_issue.closest('.board-column')
      $col_2 = $('.board-column[data-column="' + column + '"]')
      col_1_url = "/boards/#{board}/columns/#{$col_1.data('column')}"
      col_2_url = "/boards/#{board}/columns/#{$col_2.data('column')}"

      # класс активной колонки
      $('.move-to-column li').removeClass 'active'
      $(@).addClass 'active'

      # перемещение тикета в DOMe
      $column = $('.board-column[data-column="' + column + '"]')
      clone = $current_issue
      $current_issue.remove()
      $('.issues', $column).prepend(clone)

      # урл перемещения
      path = "/boards/#{board}/issues/#{issue}/move_to/#{column}"
      $.get path

      # сохранение порядка тиетов в измененных колонках
      col_1_issues = empty_check($col_1.find('.issues').sortable('serialize'), '')
      col_2_issues = empty_check($col_2.find('.issues').sortable('serialize'), issue)
      save_order col_1_url, col_1_issues
      save_order col_2_url, col_2_issues

load_comments = ->
  console.log 'load comments'

  $issue_comments = $('.issue-comments')
  comments_url = $issue_comments.data('url')

  $issue_comments.append('<div class="b-preloader horizontal"></div>')

  $.get comments_url, {}, (comments) ->
    setTimeout ->
        $issue_comments.html(comments)
        $issue_comments.trigger 'comments:load'
      , 200

open_new_comment_form = ($editable_node) ->
  console.log 'open new comment form'

  setTimeout ->
      $editable_node
        .hide()
        .next().show().addClass 'active'
        .find('textarea').val('').focus()
    , 300

open_form = ($editable_node) ->
  console.log 'open form'
  #close_active_form()

  setTimeout ->
      $editable_node
        .hide()
        .next().show().addClass('active')
        .find('textarea').focus().val($editable_node.html().trim())
    , 300

close_active_form = ->
  console.log 'close active form'
  if $('.editable-form.active').length > 0
    $('.editable-form.active')
      .hide()
      .removeClass('active')
      .prev().show()

empty_check = (issues, moving_issue) ->
  if issues
    issues
  else
    if moving_issue
      { issues: [moving_issue] }
    else
      { issues: ['empty'] }

save_order = (url, data) ->
  $.ajax
    url: url,
    method: 'PATCH',
    data: data

