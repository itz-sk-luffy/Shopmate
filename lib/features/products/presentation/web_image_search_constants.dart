/// Search engine selectors, extraction scripts, and CSS injection constants.
/// Engine-specific DOM handlers for Google, Bing, and DuckDuckGo.
class WebImageSearchConstants {
  WebImageSearchConstants._();

  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static const int maxGridImages = 60;
  static const int batchImageLimit = 40;
  static const Duration extractionTimeout = Duration(seconds: 12);

  // ---------------------------------------------------------------------------
  // URL Builders
  // ---------------------------------------------------------------------------
  static String buildSearchUrl(String engine, String query) {
    final encoded = Uri.encodeComponent(query.trim());
    switch (engine.toLowerCase()) {
      case 'bing':
        return 'https://www.bing.com/images/search?q=$encoded&form=HDRSC2';
      case 'duckduckgo':
        return 'https://duckduckgo.com/?iax=images&ia=images&q=$encoded';
      case 'google':
      default:
        // hl=en forces English layout & predictable consent buttons
        return 'https://www.google.com/search?tbm=isch&q=$encoded&hl=en';
    }
  }

  // ---------------------------------------------------------------------------
  // Search Engine Selectors & Skip Patterns
  // ---------------------------------------------------------------------------
  static String getEngineSelector(String engine) {
    switch (engine.toLowerCase()) {
      case 'bing':
        return 'a.iusc, img.mimg, .img_cont img, .iusc img, img';
      case 'duckduckgo':
        return '.tile--img__img, img.tile--img__media, .tile--img img, img';
      case 'google':
      default:
        return 'img.Q4LuWd, .rg_i, img[src*="gstatic.com/images"], img[src*="data:image"], img';
    }
  }

  static List<String> getSkipPatterns(String engine) {
    switch (engine.toLowerCase()) {
      case 'bing':
        return const [
          'favicon',
          'logo',
          'bing.com/sa/',
          'transparent.png',
          'data:image/svg',
        ];
      case 'duckduckgo':
        return const [
          'favicon',
          'logo',
          'duckduckgo.com/assets',
          'transparent.png',
          'data:image/svg',
        ];
      case 'google':
      default:
        return const [
          'gstatic.com/images/branding',
          'favicon',
          'googlelogo',
          '/logos/',
          'transparent.png',
          'cleardot.gif',
          'data:image/svg',
        ];
    }
  }

  // ---------------------------------------------------------------------------
  // JavaScript: Google Consent Auto-Bypass
  // ---------------------------------------------------------------------------
  static const String consentBypassScript = """
    (function() {
      try {
        if (window.location.href.indexOf('consent.google') !== -1) {
          var buttons = document.querySelectorAll('button');
          for (var i = 0; i < buttons.length; i++) {
            var t = (buttons[i].innerText || buttons[i].textContent || '').toLowerCase().trim();
            if (t === 'reject all' || t === 'accept all' || t === 'i agree' || t === 'agree' ||
                t.indexOf('reject all') !== -1 || t.indexOf('accept all') !== -1 ||
                t.indexOf('alle ablehnen') !== -1 || t.indexOf('alle akzeptieren') !== -1 ||
                t.indexOf('tout refuser') !== -1 || t.indexOf('tout accepter') !== -1) {
              buttons[i].click();
              return true;
            }
          }
          var forms = document.querySelectorAll('form');
          for (var f = 0; f < forms.length; f++) {
            var formButtons = forms[f].querySelectorAll('button');
            if (formButtons.length > 0) {
              formButtons[formButtons.length - 1].click();
              return true;
            }
          }
        }
      } catch (e) {}
      return false;
    })();
  """;

  // ---------------------------------------------------------------------------
  // JavaScript: Engine-Specific Image Extraction
  // ---------------------------------------------------------------------------
  static String getExtractionScript({
    required String engine,
    required String handlerName,
    int maxCount = batchImageLimit,
  }) {
    final skipPatterns = getSkipPatterns(engine);
    final skipArrayJs = skipPatterns.map((p) => "'${p.replaceAll("'", r"\'")}'").join(', ');

    return """
      (function() {
        try {
          var maxCount = $maxCount;
          var skipPatterns = [$skipArrayJs];
          var seen = {};
          var results = [];

          function isSkipped(url) {
            if (!url || url.length < 15) return true;
            for (var s = 0; s < skipPatterns.length; s++) {
              if (url.indexOf(skipPatterns[s]) !== -1) return true;
            }
            return false;
          }

          function addResult(url) {
            if (!url) return;
            if (url.indexOf('//') === 0) url = 'https:' + url;
            if (isSkipped(url)) return;
            if (!seen[url]) {
              seen[url] = true;
              results.push(url);
            }
          }

          var engine = '${engine.toLowerCase()}';

          if (engine === 'bing') {
            // Bing metadata extraction from a.iusc m JSON
            var iuscElements = document.querySelectorAll('a.iusc');
            for (var i = 0; i < iuscElements.length; i++) {
              try {
                var m = JSON.parse(iuscElements[i].getAttribute('m') || '{}');
                var murl = m.murl || m.turl;
                if (murl) addResult(murl);
                if (results.length >= maxCount) break;
              } catch(e) {}
            }

            // Fallback to Bing img.mimg elements
            if (results.length < maxCount) {
              var mimgs = document.querySelectorAll('img.mimg, .img_cont img, img');
              for (var j = 0; j < mimgs.length; j++) {
                var el = mimgs[j];
                var w = el.naturalWidth || el.width || el.clientWidth || 0;
                if (w > 0 && w < 80) continue;
                var src = el.currentSrc || el.src || el.getAttribute('data-src') || '';
                addResult(src);
                if (results.length >= maxCount) break;
              }
            }
          } else if (engine === 'duckduckgo') {
            // DuckDuckGo image extraction
            var ddgElements = document.querySelectorAll('.tile--img__img, img.tile--img__media, .tile--img img, img');
            for (var k = 0; k < ddgElements.length; k++) {
              var el = ddgElements[k];
              var w = el.naturalWidth || el.width || el.clientWidth || 0;
              if (w > 0 && w < 80) continue;
              var src = el.currentSrc || el.src || el.getAttribute('data-src') || '';
              addResult(src);
              if (results.length >= maxCount) break;
            }
          } else {
            // Google image extraction
            var gElements = document.querySelectorAll('img.Q4LuWd, .rg_i, img[src*="gstatic.com/images"], img[src*="data:image"], img');
            for (var g = 0; g < gElements.length; g++) {
              var el = gElements[g];
              var nw = el.naturalWidth || 0;
              var w = nw || el.width || el.clientWidth || 0;
              if (nw > 0 && nw < 80) continue;
              if (w > 0 && w < 80) continue;

              var src = el.currentSrc || el.src || el.getAttribute('data-src') || el.getAttribute('data-iurl') || '';
              addResult(src);
              if (results.length >= maxCount) break;
            }
          }

          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('$handlerName', results);
          }
          return results.length;
        } catch (e) {
          return 0;
        }
      })();
    """;
  }

  // ---------------------------------------------------------------------------
  // JavaScript: Infinite Scroll + Extraction
  // ---------------------------------------------------------------------------
  static String getScrollAndExtractScript({
    required String engine,
    required String handlerName,
    int maxCount = batchImageLimit,
  }) {
    final extractionCode = getExtractionScript(
      engine: engine,
      handlerName: handlerName,
      maxCount: maxCount,
    );

    return """
      (function() {
        try {
          window.scrollTo(0, document.body.scrollHeight || document.documentElement.scrollHeight);
          setTimeout(function() {
            $extractionCode
          }, 800);
        } catch (e) {}
      })();
    """;
  }

  // ---------------------------------------------------------------------------
  // JavaScript: Tap selection for Full Browser Mode fallback
  // ---------------------------------------------------------------------------
  static const String tapSelectionScript = """
    (function() {
      function attachListeners() {
        var images = document.getElementsByTagName('img');
        for (var i = 0; i < images.length; i++) {
          var img = images[i];
          if (img.getAttribute('data-shopmate-bound') === 'true') continue;
          img.setAttribute('data-shopmate-bound', 'true');

          img.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            var bestSrc = this.currentSrc || this.src || this.getAttribute('data-src') || this.getAttribute('data-iurl') || '';
            if (bestSrc && bestSrc.length > 10) {
              if (bestSrc.indexOf('//') === 0) {
                bestSrc = 'https:' + bestSrc;
              }
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('onImageSelected', bestSrc);
              }
            }
          }, true);
        }
      }

      attachListeners();
      var observer = new MutationObserver(attachListeners);
      observer.observe(document.body || document.documentElement, {
        childList: true,
        subtree: true
      });
    })();
  """;

  // ---------------------------------------------------------------------------
  // CSS: Hide Header, Tabs, Chips, Footer & Set Surface Background
  // ---------------------------------------------------------------------------
  static String getHideCss(String engine, String surfaceHex) {
    switch (engine.toLowerCase()) {
      case 'bing':
        return """
          #b_header, header, #b_footer, footer, .b_foot, #id_h, #b_idProviders, .header {
            display: none !important;
          }
          body, html {
            background-color: $surfaceHex !important;
          }
        """;
      case 'duckduckgo':
        return """
          header, #header, .header, footer, .footer, .js-header {
            display: none !important;
          }
          body, html {
            background-color: $surfaceHex !important;
          }
        """;
      case 'google':
      default:
        return """
          header, #header, #searchform, [role="navigation"], [role="search"],
          #top_nav, .hdtb-mbt, #fbar, footer, .fbar, .WE0U5b, .k77Iif, .mR49bd,
          .T4T2eb, .iu-card-header, .f6F9Be, .mNsIwf {
            display: none !important;
          }
          body, html {
            background-color: $surfaceHex !important;
          }
        """;
    }
  }
}
