const reMatchBlocks = /^(\(#[^)]+\))\s*(.*)[\r\n]+(<hexoPostRenderCodeBlock><figure[^>]*>)(.*?)(<\/figure><\/hexoPostRenderCodeBlock>)/gm;

hexo.extend.filter.register('before_post_render', function augmentFigures(data) {
    data.content = data.content.replace(reMatchBlocks,
        (match, directive, caption, start, table ,end) => {
            let captionHtml = '';
            let directiveHtml = '  <figcaption class="directive">' + directive + '</figcaption>\n'
            if (caption) {
                captionHtml += '  <figcaption class="caption">' + caption + '</figcaption>\n';
            }
            
            return start + captionHtml + table + directiveHtml + end;
        }
    );
    return data;

}, 10);
