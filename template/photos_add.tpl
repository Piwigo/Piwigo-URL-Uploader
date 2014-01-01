{combine_css path=$URLUPLOADER_PATH|cat:'template/style.css'}
{combine_script id='URI' load='footer' path=$URLUPLOADER_PATH|cat:'template/URI.min.js'}
{combine_css path=$URLUPLOADER_PATH|cat:'template/jquery.textarea-lines-numbers.css'}
{combine_script id='createTextareaWithLines' load='footer' require='jquery.ui.resizable' path=$URLUPLOADER_PATH|cat:'template/jquery.textarea-lines-numbers.js'}

{if $upload_mode == 'multiple'}
{combine_script id='jquery.ajaxmanager' load='footer' path='themes/default/js/plugins/jquery.ajaxmanager.js'}
{combine_script id='jquery.jgrowl' load='footer' require='jquery' path='themes/default/js/plugins/jquery.jgrowl_minimized.js' }
{combine_script id='jquery.ui.progressbar' load='footer'}
{combine_css path='themes/default/js/plugins/jquery.jgrowl.css'}
{/if}

{include file='include/colorbox.inc.tpl'}
{include file='include/add_album.inc.tpl'}


{footer_script}
(function($){
  var allowed_extensions = new Array('jpeg','jpg','png','gif');

  $('#hideErrors').click(function() {
    $('#formErrors').hide();
    return false;
  });
  
  $('#uploadWarningsSummary a.showInfo').click(function() {
    $('#uploadWarningsSummary').hide();
    $('#uploadWarnings').show();
    return false;
  });
  
  $('#showPermissions').click(function() {
    $(this).parent('.showFieldset').hide();
    $('#permissions').show();
    return false;
  });

  {* <!-- MULTIPLE UPLOAD --> *}
  {if $upload_mode == 'multiple'}
  function checkUploadStart() {
    var nbErrors = 0;
    
    $('#formErrors').hide();
    $('#formErrors li').hide();

    if ($('#albumSelect option:selected').length == 0) {
      $('#formErrors #noAlbum').show();
      nbErrors++;
    }
    
    var nbFiles = $('table#links tr.pending').length;
    
    if (nbFiles == 0) {
      $('#formErrors #noPhoto').show();
      nbErrors++;
    }

    if (nbErrors != 0) {
      $('#formErrors').show();
      return false;
    }
    else {
      return true;
    }
  }

  function trim (str) {
    return str.replace(/^\s+/g,'').replace(/\s+$/g,'')
  }

  $('input[name=add_links]').click(function() {
    $input = $('textarea#urls');
    
    if ($input.val() != '') {
      $('table#links').show();
      
      var lines = $input.val().split('\n');
      var html = '';
      $input.val('');
      
      for (i in lines) {
        line = lines[i].split('|');
        item = {};
        
        // no name given
        if (line.length == 1) {
          uri = new URI(trim(line[0]));
          item.name = '';
        }
        // name given
        else {
          uri = new URI(trim(line[1]));
          item.name = trim(line[0]);
        }
        
        uri.fragment('');
        item.url = uri.href();
        item.short_url = item.url;
        
        // shortened url for display
        if (item.url.length > 40) {
          item.short_url = item.url.substring(0, 15) + ' ... ' + item.url.substring(item.url.length-15);
        }
        
        // check if consistent url
        if (uri.is('relative')) {
          item.status = 'error';
          item.info = '{'Invalid file URL'|translate|escape:javascript}';
        }
        else {
          // check if good extension
          if (allowed_extensions.indexOf(uri.suffix().toLowerCase()) == -1) {
            item.status = 'error';
            item.info = '{'Invalid file type'|translate|escape:javascript}';
          }
          else {
            item.status = 'pending';
            item.info = '{'Pending'|translate|escape:javascript}';
          }
        }
        
        // add link to table
        html+= '<tr class="'+ item.status + '" data-name="'+ item.name +'" data-url="'+ item.url +'">'+
          '<td>'+ item.name +'</td>'+
          '<td><a href="'+ item.url +'">'+ item.short_url +'</a></td>'+
          '<td>'+ item.info +'</td>'+
          '<td><a class="delete" title="{'Delete this item'|translate|escape:javascript}">&nbsp;</a></td>'+
        '</tr>';
      }
      
      $('table#links tbody').append(html);
    }
    
    $input.focus();
    return false;
  });

  $('table#links').on('click', 'a.delete', function() {
    $(this).parents('tr').remove();
    $('textarea#urls').focus();
  });

  // AJAX MANAGER
  var import_done = 0;
  var import_selected = 0;
  var queuedManager = $.manageAjax.create('queued', {
    queue: true,  
    maxRequests: 1
  });

  function performImport(file_url, category, name, level, url_in_comment, $target) {
    queuedManager.add({
      type: 'GET',
      dataType: 'json',
      url: 'ws.php',
      data: {
        method: 'pwg.images.addRemote',
        file_url: file_url,
        category: category,
        name: name,
        level: level,
        url_in_comment: url_in_comment,
        format: 'json'
      },
      success: function(data) {
        if (data['stat'] == 'ok') {
          $target.remove();
          $('#uploadedPhotos').parent('fieldset').show();
          $('#uploadedPhotos').prepend('<img src="'+ data['result']['thumbnail_url'] +'" class="thumbnail"> ');
          $('#uploadForm').append('<input type="hidden" name="imageIds[]" value="'+ data['result']['image_id'] +'">');
        }
        else {
          $.jGrowl(name +' : '+ data['message'], { 
            theme: 'error', sticky: true, 
            header: '{'ERROR'|translate}'
          });
            
          $target.children('td:nth-child(3)').html(lang[data['message']]);
          $('#uploadForm').append('<input type="hidden" name="onUploadError[]" value="'+ file_url +' : '+ data['message'] +'">');
        }
        
        import_done++;
        $('#progressbar').progressbar({ value: import_done });
        $('#progressCurrent').text(import_done);
        
        if (import_done == import_selected) {
          $('#uploadForm').submit();
        }
      },
      error: function(data) {
        $.jGrowl(name +' : '+ '{'an error happened'|translate|escape:javascript}', { 
          theme: 'error', sticky: true, 
          header: '{'ERROR'|translate}'
        });
        
        $target.children('td:nth-child(3)').html('{'an error happened'|translate|escape:javascript}');
      }
    });
  }

  $('input[name=submit_upload]').click(function() {
    if (!checkUploadStart()) {
      return false;
    }
    
    import_selected = $('table#links tr.pending').length;
    
    $('table#links a.delete').hide();
    
    $('#progressbar').progressbar({ max: import_selected, value:0 });
    $('#progressMax').text(import_selected);
    $('#progressCurrent').text(0);
    $('#uploadProgress').show();
    
    $('table#links tr.pending').each(function() {
      performImport(
        $(this).data('url'),
        $('select[name=category] option:selected').val(),
        $(this).data('name'),
        $('select[name=level] option:selected').val(),
        $('input[name=url_in_comment]').is(':checked'),
        $(this)
        );
    });
      
    return false;
  });

  $('textarea#urls').textareaLinesNumbers({
    lines:999,
    trailing:'.'
  });


{* <!-- SINGLE UPLOAD --> *}
{else}
  function checkUploadStart() {
    var nbErrors = 0;
    
    $('#formErrors').hide();
    $('#formErrors li').hide();

    if ($('#albumSelect option:selected').length == 0) {
      $('#formErrors #noAlbum').show();
      nbErrors++;
    }
    
    if ($('input[name=file_url]').val() == '') {
      $('#formErrors #urlEmpty').show();
      nbErrors++;
    }
    else {
      uri = new URI($('input[name=file_url]').val());
      if (uri.is('relative')) {
        $('#formErrors #urlError').show();
        nbErrors++;
      }
      else if (allowed_extensions.indexOf(uri.suffix().toLowerCase()) == -1) {
        $('#formErrors #typeError').show();
        nbErrors++;
      }
    }

    if (nbErrors != 0) {
      $('#formErrors').show();
      return false;
    }
    else {
      return true;
    }
  }

  $('input[name=submit_upload]').click(function() {
    return checkUploadStart();
  });
{/if}

}(jQuery));
{/footer_script}


{html_style}
a.delete {
  background:url('admin/include/uploadify/cancel.png');
}
{/html_style}


<div class="titrePage">
  <h2>{'Upload Photos'|translate} {$TABSHEET_TITLE}</h2>
</div>

<div id="photosAddContent">

{if count($setup_errors) > 0}
  <div class="errors">
    <ul>
    {foreach from=$setup_errors item=error}
      <li>{$error}</li>
    {/foreach}
    </ul>
  </div>
{else}

{if count($setup_warnings) > 0}
  <div class="warnings">
    <ul>
      {foreach from=$setup_warnings item=warning}
      <li>{$warning}</li>
      {/foreach}
    </ul>
    <div class="hideButton" style="text-align:center"><a href="{$hide_warnings_link}">{'Hide'|translate}</a></div>
  </div>
{/if}
  
{if !empty($thumbnails)}
  <fieldset>
    <legend>{'Uploaded Photos'|translate}</legend>
    <div>
    {foreach from=$thumbnails item=thumbnail}
      <a href="{$thumbnail.link}" class="externalLink">
        <img src="{$thumbnail.src}" alt="{$thumbnail.file}" title="{$thumbnail.title}" class="thumbnail">
      </a>
    {/foreach}
    </div>
    
    <p id="batchLink"><a href="{$batch_link}">{$batch_label}</a></p>
  </fieldset>
  
  <p style="margin:10px"><a href="{$another_upload_link}">{'Add another set of photos'|translate}</a></p>
  
{else}
  <div id="formErrors" class="errors" style="display:none">
    <ul>
      <li id="noAlbum">{'Select an album'|translate}</li>
      <li id="noPhoto">{'Select at least one photo'|translate}</li>
      <li id="urlEmpty">{'File URL is empty'|translate}</li>
      <li id="urlError">{'Invalid file URL'|translate}</li>
      <li id="typeError">{'Invalid file type'|translate}</li>
    </ul>
    <div class="hideButton" style="text-align:center"><a href="#" id="hideErrors">{'Hide'|translate}</a></div>
  </div>

  <form id="uploadForm" enctype="multipart/form-data" method="post" action="{$form_action}" class="properties">
    <fieldset>
      <legend>{'Drop into album'|translate}</legend>

      <span id="albumSelection"{if count($category_options) == 0} style="display:none"{/if}>
      <select id="albumSelect" name="category">
        {html_options options=$category_options selected=$category_options_selected}
      </select>
      <br>{'... or '|translate}</span><a href="#" class="addAlbumOpen" title="{'create a new album'|translate}">{'create a new album'|translate}</a>
      
    </fieldset>

    <fieldset>
      <legend>{'Select files'|translate}</legend>
      
      <p id="uploadWarningsSummary">
        {'Allowed file types: %s.'|translate:$upload_file_types}
      {if isset($max_upload_resolution)}
        {$max_upload_resolution}Mpx
        <a class="showInfo" title="{'Learn more'|translate}">i</a>
      {/if}
      </p>

      <p id="uploadWarnings">
        {'Allowed file types: %s.'|translate:$upload_file_types}
      {if isset($max_upload_resolution)}
        {'Approximate maximum resolution: %dM pixels (that\'s %dx%d pixels).'|translate:$max_upload_resolution:$max_upload_width:$max_upload_height}
      {/if}
      </p>

{* <!-- SINGLE UPLOAD --> *}
    {if $upload_mode == 'single'}
      <ul>
        <li>
          <label>
            <span class="property">{'File URL'|translate}</span>
            <input type="text" name="file_url" size="70">
          </label>
        </li>
        <li>
          <label>
            <span class="property">{'Photo name'|translate}</span>
            <input type="text" name="photo_name" size="40">
          </label>
        </li>
        <li>
          <label>
            <span class="property"><input type="checkbox" name="url_in_comment" checked="checked"></span>
            {'Add website URL in photo description'|translate}
          </label>
        </li>
      </ul>      
      
      <p id="uploadModeInfos">{'Want to upload many files? Try the <a href="%s">multiple uploader</a> instead.'|translate:$switch_url}</p>

{* <!-- MULTIPLE UPLOAD --> *}
    {else}
      <table id="links" class="table2" style="display:none;">
        <thead>
          <tr class="throw">
            <th style="width:150px;">{'Photo name'|translate}</th>
            <th>{'File URL'|translate}</th>
            <th style="width:150px;">{'Status'|translate}</th>
            <th style="width:20px;"></th>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
      
      <p>
        {'One link by line, separate photo name and url with a &laquo; | &raquo;. Photo name is optional.'|translate}
        <br>
        <textarea id="urls"></textarea>
      </p>
      
      <p>
        <label>
          <input type="checkbox" name="url_in_comment" checked="checked">
          {'Add website URL in photo description'|translate}
        </label>
      </p>
      
      <input type="submit" name="add_links" value="{'Add links'|translate}">
      
      <p id="uploadModeInfos">{'Multiple uploader doesn\'t work? Try the <a href="%s">single uploader</a> instead.'|translate:$switch_url}</p>
    {/if}
    </fieldset>

    <p class="showFieldset"><a id="showPermissions" href="#">{'Manage Permissions'|translate}</a></p>

    <fieldset id="permissions" style="display:none">
      <legend>{'Who can see these photos?'|translate}</legend>

      <select name="level" size="1">
        {html_options options=$level_options selected=$level_options_selected}
      </select>
    </fieldset>
    
    <p>
      <input class="submit" type="submit" name="submit_upload" value="{'Start Upload'|translate}">
    </p>
  </form>

  <div id="uploadProgress" style="display:none">
    {'Photo %s of %s'|translate:'<span id="progressCurrent">1</span>':'<span id="progressMax">10</span>'}
    <br>
    <div id="progressbar"></div>
  </div>

  <fieldset style="display:none">
    <legend>{'Uploaded Photos'|translate}</legend>
    <div id="uploadedPhotos"></div>
  </fieldset>

{/if} {* empty($thumbnails) *}
{/if} {* $setup_errors *}

<br>
</div> <!-- photosAddContent -->