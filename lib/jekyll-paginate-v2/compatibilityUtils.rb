module Jekyll 
  module PaginateV2

    #
    # Static utility functions that provide backwards compatibility with the old 
    # jekyll-paginate gem that this new version superseeds (this code is here to ensure)
    # that sites still running the old gem work without problems
    # (REMOVE AFTER 2018-01-01)
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
      def self.paginate(legacy_config, all_posts, page, &page_create_proc )
        pages = Utils.calculate_number_of_pages(all_posts, legacy_config['per_page'].to_i)
        (1..pages).each do |num_page|
          pager = Paginator.new( legacy_config['per_page'], legacy_config['permalink'], all_posts, num_page, pages, page.url )
          if num_page > 1
            newpage = page_create_proc.call( page.dir, page.name )
            newpage.pager = pager
            newpage.dir = Utils.paginate_path(page.url, num_page, legacy_config['permalink'])
          else
            page.pager = pager
          end
        end
      end

    end # class CompatibilityUtils
  end # module PaginateV2
end # module Jekyll