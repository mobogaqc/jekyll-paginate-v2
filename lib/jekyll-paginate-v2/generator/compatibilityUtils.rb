module Jekyll 
  module PaginateV2::Generator

    class CompatibilityPaginationPage < Page
      def initialize(site, base, dir, template_path)
        @site = site
        @base = base
        @dir = dir
        @template = template_path
        @name = 'index.html'

        templ_dir = File.dirname(template_path)
        templ_file = File.basename(template_path)

        # Path is only used by the convertible module and accessed below when calling read_yaml
        # in our case we have the path point to the original template instead of our faux new pagination page
        @path = if site.in_theme_dir(base) == base # we're in a theme
                  site.in_theme_dir(base, templ_dir, templ_file)
                else
                  site.in_source_dir(base, templ_dir, templ_file)
                end
        
        self.process(@name)
        self.read_yaml(templ_dir, templ_file)

        data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find(File.join(templ_dir, templ_file), type, key)
        end

      end
    end # class CompatibilityPaginationPage

    #
    # Static utility functions that provide backwards compatibility with the old 
    # jekyll-paginate gem that this new version superseeds (this code is here to ensure)
    # that sites still running the old gem work without problems
    # (REMOVE AFTER 2018-01-01)
    #
    # THIS CLASS IS ADAPTED FROM THE ORIGINAL IMPLEMENTATION AND WILL BE REMOVED, THERE ARE DELIBERATELY NO TESTS FOR THIS CLASS
    #
    class CompatibilityUtils

      # Public: Find the Jekyll::Page which will act as the pager template
      #
      # Returns the Jekyll::Page which will act as the pager template
      def self.template_page(site_pages, config_source, config_paginate_path)
        site_pages.select do |page|
          CompatibilityUtils.pagination_candidate?(config_source, config_paginate_path, page)
        end.sort do |one, two|
          two.path.size <=> one.path.size
        end.first
      end

      # Static: Determine if a page is a possible candidate to be a template page.
      #         Page's name must be `index.html` and exist in any of the directories
      #         between the site source and `paginate_path`.
      def self.pagination_candidate?(config_source, config_paginate_path, page)
        page_dir = File.dirname(File.expand_path(Utils.remove_leading_slash(page.path), config_source))
        paginate_path = Utils.remove_leading_slash(config_paginate_path)
        paginate_path = File.expand_path(paginate_path, config_source)
        page.name == 'index.html' && CompatibilityUtils.in_hierarchy(config_source, page_dir, File.dirname(paginate_path))
      end

      # Determine if the subdirectories of the two paths are the same relative to source
      #
      # source        - the site source
      # page_dir      - the directory of the Jekyll::Page
      # paginate_path - the absolute paginate path (from root of FS)
      #
      # Returns whether the subdirectories are the same relative to source
      def self.in_hierarchy(source, page_dir, paginate_path)
        return false if paginate_path == File.dirname(paginate_path)
        return false if paginate_path == Pathname.new(source).parent
        page_dir == paginate_path ||
          CompatibilityUtils.in_hierarchy(source, page_dir, File.dirname(paginate_path))
      end

      # Paginates the blog's posts. Renders the index.html file into paginated
      # directories, e.g.: page2/index.html, page3/index.html, etc and adds more
      # site-wide data.
      #
      def self.paginate(legacy_config, all_posts, page, page_add_lambda )
        pages = Utils.calculate_number_of_pages(all_posts, legacy_config['per_page'].to_i)
        (1..pages).each do |num_page|
          pager = Paginator.new( legacy_config['per_page'], page.url, legacy_config['permalink'], all_posts, num_page, pages )
          if num_page > 1
            template_full_path = File.join(page.site.source, page.path)
            template_dir = File.dirname(page.path)
            newpage = CompatibilityPaginationPage.new(page.site, page.site.source, template_dir, template_full_path)
            newpage.pager = pager
            newpage.dir = CompatibilityUtils.paginate_path(page.url, num_page, legacy_config['permalink'])
            newpage.data['autogen'] = "jekyll-paginate-v2" # Signals that this page is automatically generated by the pagination logic
            page_add_lambda.call(newpage)
          else
            page.pager = pager
          end
        end
      end

      # Static: Return the pagination path of the page
      #
      # site     - the Jekyll::Site object
      # cur_page_nr - the pagination page number
      # config - the current configuration in use
      #
      # Returns the pagination path as a string
      def self.paginate_path(template_url, cur_page_nr, permalink_format)
        return nil if cur_page_nr.nil?
        return template_url if cur_page_nr <= 1
        if permalink_format.include?(":num")
          permalink_format = Utils.format_page_number(permalink_format, cur_page_nr)
        else
          raise ArgumentError.new("Invalid pagination path: '#{permalink_format}'. It must include ':num'.")
        end

        Utils.ensure_leading_slash(permalink_format)
      end #function paginate_path

    end # class CompatibilityUtils
  end # module PaginateV2
end # module Jekyll