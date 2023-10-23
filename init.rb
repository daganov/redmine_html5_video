Redmine::Plugin.register :redmine_html5_video do
  name 'Html5 video macros'
  description 'Embeds video URLs. Usage (as macro): video(ID|URL|YOUTUBE_URL)'
  version '0.1'
  author 'Aganov D.'
  url 'https://github.com/daganov/redmine_html5_video.git'
  author_url 'https://github.com/daganov/redmine_html5_video.git'
end

Redmine::WikiFormatting::Macros.register do
    desc "Wiki embed html5 video:\n\n" +
        "{{video(file [, width] [, height], [, controls])}}"
    macro :video do |obj, args|
        width      = args[1].gsub(/\D/,'') if args[1]
        height     = args[2].gsub(/\D/,'') if args[2]
        controls   = args[3]
        width    ||= 800
        # height   ||= 600
        if (controls == '0' || controls == 0 || controls == 'false')
                controls = nil
        else
                controls = true
        end

        attachment = obj.attachments.find_by_filename(args[0]) if (obj.respond_to?('attachments') && obj.attachments.length() > 0)

        if attachment
            file_url = url_for(:only_path => false, :controller => 'attachments', :action => 'download', :id => attachment, :filename => attachment.filename)
        else
            file_url = args[0].gsub(/<.*?>/, '').gsub(/&lt;.*&gt;/,'')
        end

        case file_url
        # check for youtube-URL, extract youtubeID and assign to local variable {youtubeID}
        when /^https?:\/\/((www\.)?youtube\.com\/(watch\?([\w\d\=]*\&)*v=|embed\/){1}|youtu\.be\/)(?<youtubeID>[\w\d\-]*)((\&|\/)[\w\d\=\-]*)*$/
                if !controls
                        yt_params="?controls=0"
                else
                        yt_params="?nix=#{controls}"
                end
                video_url = "https://www.youtube.com/embed/#{$LAST_MATCH_INFO['youtubeID']}#{yt_params}"
                embed_typ = "iframe"
        else
                # Currently, there are 3 supported video formats for the <video> element: MP4, WebM, and Ogg
                # http://www.w3schools.com/tags/tag_video.asp
                video_url = file_url
                embed_typ = "video"
                case file_url
                when /^https?:\/\/(.*\/)?(?<video_name>.*)\.(?<video_format>mp4|ogg|webm)(\?.*)?$/
                        mime_type = "video/#{$LAST_MATCH_INFO['video_format']}"
                else
                        if $LAST_MATCH_INFO == nil
                                video_url = "broken video url"
                                return video_url
                        else
                                video_url = "unknown filetype: #{$LAST_MATCH_INFO['video_format']}"
                        end
                end
        end

        case embed_typ
        when "iframe"
                content_tag(:iframe, nil, :src  => video_url, :width => width )
        else
                content_tag(:video, tag(:source, :src => video_url, :type => mime_type ) ,  :width => width, :controls => controls )
        end
    end
end
