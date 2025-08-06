{combine_css path=$URLUPLOADER_PATH|cat:'template/style.css'}
{combine_script id='URI' load='footer' path=$URLUPLOADER_PATH|cat:'template/URI.min.js'}

{combine_css path=$URLUPLOADER_PATH|cat:'template/jquery.textarea-lines-numbers.css'}
{combine_script id='jquery.textarea-lines-numbers' load='footer' require='jquery.ui.resizable' path=$URLUPLOADER_PATH|cat:'template/jquery.textarea-lines-numbers.js'}

{combine_script id='common' load='footer' path='admin/themes/default/js/common.js'}
{combine_script id='jquery.ajaxmanager' load='footer' path='themes/default/js/plugins/jquery.ajaxmanager.js'}

{combine_css path="themes/default/js/plugins/jquery.jgrowl.css"}
{combine_script id='jquery.jgrowl' load='footer' require='jquery' path='themes/default/js/plugins/jquery.jgrowl_minimized.js' }

{combine_script id='LocalStorageCache' load='footer' path='admin/themes/default/js/LocalStorageCache.js'}

{combine_script id='jquery.selectize' load='footer' path='themes/default/js/plugins/selectize.min.js'}
{combine_css id='jquery.selectize' path="themes/default/js/plugins/selectize.{$themeconf.colorscheme}.css"}

{include file='include/colorbox.inc.tpl'}
{include file='include/add_album.inc.tpl'}


{footer_script}
var pwg_token = '{$pwg_token}';
{* <!-- CATEGORIES --> *}
var categoriesCache = new CategoriesCache({
  serverKey: '{$CACHE_KEYS.categories}',
  serverId: '{$CACHE_KEYS._hash}',
  rootUrl: '{$ROOT_URL}'
});

categoriesCache.selectize(jQuery('[data-selectize=categories]'), {
  filter: function(categories, options) {
    if (categories.length > 0) {
      jQuery("#albumSelection, .selectFiles, .showFieldset").show();
    }
    
    return categories;
  }
});

jQuery('[data-add-album]').pwgAddAlbum({
  cache: categoriesCache,
  afterSelect: function() {
    jQuery("#albumSelection, .selectFiles, .showFieldset").show();
  }
});

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

  function checkUploadStart() {
    var nbErrors = 0;
    
    $('#formErrors, #formErrors li').hide();
    
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

  $('#addFiles').click(function(e) {
    var ok = 0;
    
    $input = $('textarea#urls');
    
    if ($input.val() != '') {
      var lines = $input.val().split('\n');
      var html = '';
      
      for (i in lines) {
        var line = trim(lines[i]);
        
        if (!line) {
          continue;
        }
        
        line = line.split('|');
        var item = {};
        
        // no name given
        if (line.length == 1) {
          uri = new URI(trim(line[0]));
          item.name = uri.filename(true).replace(new RegExp('\\.'+uri.suffix(true)+'$'), '');
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
        
        if (item.status == 'pending') {
          ok++;
        }
        
        // add link to table
        html+= '<tr class="'+ item.status + '" data-name="'+ item.name +'" data-url="'+ item.url +'">'+
          '<td>'+ item.name +'</td>'+
          '<td><a href="'+ item.url +'" class="colorbox">'+ item.short_url +'</a></td>'+
          '<td>'+ item.info +'</td>'+
          '<td><i class="icon-cancel-circled delete" title="{'Delete this item'|translate|escape:javascript}"></i></td>'+
        '</tr>';
      }
      
      $('table#links tbody').append(html);
    }
    
    if (ok > 0) {
      $('#startUpload').prop('disabled', false);
      $('table#links').show();
    }
    
    $input.val('');
    $input.focus();
    
    e.preventDefault();
  });
  
  $('table#links').on('click', '.colorbox', function(e) {
      $.colorbox({
        href: this.href,
        maxWidth: '80%',
        maxHeight: '90%'
      });
      e.preventDefault();
  });

  $('table#links').on('click', '.delete', function() {
    var $parent = $(this).closest('table');
    $(this).closest('tr').remove();
    $('textarea#urls').focus();
    $parent.toggle($parent.find('tr').length > 0);
    $('#startUpload').prop('disabled', $parent.find('tr.pending').length == 0);
  });

  // AJAX MANAGER
  var import_done = 0;
  var import_success = 0;
  var import_selected = 0;
  var uploadedPhotos = [];
  var uploadCategory = null;
  
  var queuedManager = $.manageAjax.create('queued', {
    queue: true,  
    maxRequests: 2
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
        if (data.stat == 'ok') {
          $target.remove();
          
          var html = '<a href="admin.php?page=photo-'+data.result.image_id+'" target="_blank">';
          html += '<img src="'+data.result.src+'" class="thumbnail" title="'+data.result.name+'">';
          html += '</a> ';
          
          jQuery("#uploadedPhotos").prepend(html).parent('fieldset').show();
          
          uploadedPhotos.push(parseInt(data.result.image_id));
          uploadCategory = data.result.category;
          import_success++;
        }
        else {
          $.jGrowl(name +' : '+ data['message'], { 
            theme: 'error', sticky: true, 
            header: '{'ERROR'|translate}'
          });
            
          $target.addClass('error').children('td:nth-child(3)').html(data.message);
          $('#uploadForm').append('<input type="hidden" name="onUploadError[]" value="'+ file_url +' : '+ data.message +'">');
        }
        
        import_done++;

        $('#uploadingActions .progressbar').width((import_done/import_selected*100)+'%');
        
        if (import_done == import_selected) {
          finishUpload();
        }
      },
      error: function(data) {
        $.jGrowl(name +' : '+ '{'an error happened'|translate|escape:javascript}', { 
          theme: 'error', sticky: true, 
          header: '{'ERROR'|translate}'
        });
        
        $target.addClass('error').children('td:nth-child(3)').html('{'an error happened'|translate|escape:javascript}');
      }
    });
  }
  
  function finishUpload() {
    $.ajax({
      url: "ws.php?format=json&method=pwg.images.uploadCompleted",
      type: "POST",
      data: {
        pwg_token: pwg_token,
        image_id: uploadedPhotos.join(","),
        category_id: uploadCategory.id,
      }
    });

    jQuery(".infos").append('<ul><li>'+sprintf("{'%d photos uploaded'|translate|escape:javascript}", uploadedPhotos.length)+'</li></ul>');
    
    if (uploadCategory) {
      var html = sprintf(
        "{'Album "%s" now contains %d photos'|translate|escape:javascript}",
        '<a href="admin.php?page=album-'+uploadCategory.id+'">'+uploadCategory.label+'</a>',
        parseInt(uploadCategory.nb_photos)
      );

      jQuery(".infos ul").append('<li>'+html+'</li>');
    }

    jQuery(".selectAlbum, #uploadingActions, #permissions, .showFieldset").hide();
    jQuery(".infos, .afterUploadActions").show();
    
    if (import_success == import_selected) {
      jQuery(".selectFiles").hide();
    }
    
    jQuery(".batchLink").attr("href", "admin.php?page=photos_add&section=direct&batch="+uploadedPhotos.join(","));
    jQuery(".batchLink").html(sprintf("{'Manage this set of %d photos'|translate|escape:javascript}", uploadedPhotos.length));

    jQuery(window).unbind('beforeunload');
  }

  $('#startUpload').click(function(e) {
    if (!checkUploadStart()) {
      return false;
    }
    
    import_selected = $('table#links tr.pending').length;
    
    $('table#links a.delete').hide();
    $('#startUpload, #addFiles').hide();
    $('#uploadingActions').show();
    $("select[name=level]").attr("disabled", "disabled");
    
    $(window).bind('beforeunload', function() {
      return "{'Upload in progress'|translate|escape}";
    });
    
    var album = $('select[name=category] option:selected').val(),
        level = $('select[name=level] option:selected').val(),
        add_url = $('input[name=url_in_comment]').is(':checked');
    
    $('table#links tr.pending').each(function() {
      performImport(
        $(this).data('url'),
        album,
        $(this).data('name'),
        level,
        add_url,
        $(this)
        );
    });
      
    e.preventDefault();
  });

  $('textarea#urls').textareaLinesNumbers({
    lines:999,
    trailing:'.'
  });

}(jQuery));
{/footer_script}


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

  <div class="infos" style="display:none"></div>

  <p class="afterUploadActions" style="margin:10px; display:none;"><a class="batchLink"></a> | <a href="{$URLUPLOADER_ADMIN}">{'Add another set of photos'|@translate}</a></p>
  
  <div id="formErrors" class="errors" style="display:none">
    <ul>
      <li id="noPhoto">{'Select at least one photo'|translate}</li>
      <li id="urlEmpty">{'File URL is empty'|translate}</li>
      <li id="urlError">{'Invalid file URL'|translate}</li>
      <li id="typeError">{'Invalid file type'|translate}</li>
    </ul>
    <div class="hideButton" style="text-align:center"><a href="#" id="hideErrors">{'Hide'|translate}</a></div>
  </div>

  <form id="uploadForm" class="properties">
    <fieldset class="selectAlbum">
      <legend>{'Drop into album'|@translate}</legend>

      <span id="albumSelection" style="display:none">
      <select data-selectize="categories" data-value="{$selected_category|@json_encode|escape:html}"
        data-default="first" name="category" style="width:600px"></select>
      <br>{'... or '|@translate}</span>
      <a href="#" data-add-album="category" title="{'create a new album'|@translate}">{'create a new album'|@translate}</a>
    </fieldset>

    <p class="showFieldset" style="display:none"><a id="showPermissions" href="#">{'Manage Permissions'|translate}</a></p>

    <fieldset id="permissions" style="display:none">
      <legend>{'Who can see these photos?'|translate}</legend>

      <select name="level" size="1">
        {html_options options=$level_options selected=$level_options_selected}
      </select>
    </fieldset>

    <fieldset class="selectFiles" style="display:none">
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
      
      <button id="addFiles" class="buttonLike icon-plus-circled">{'Add links'|translate}</button>
    </fieldset>
      
    <p class="showFieldset" style="display:none">
      <label>
        <input type="checkbox" name="url_in_comment" checked="checked">
        {'Add website URL in photo description'|translate}
      </label>
    </p>
    
    <div id="uploadingActions" style="display:none">
      <!--<button id="cancelUpload" class="buttonLike icon-cancel-circled">{'Cancel'|translate}</button>-->
      
      <div class="big-progressbar">
        <div class="progressbar" style="width:0%"></div>
      </div>
    </div>
      
    <button id="startUpload" class="buttonLike icon-upload" disabled>{'Start Upload'|translate}</button>
    
  </form>

  <fieldset style="display:none">
    <legend>{'Uploaded Photos'|translate}</legend>
    <div id="uploadedPhotos"></div>
  </fieldset>

{/if} {* $setup_errors *}

<br>
</div> <!-- photosAddContent -->