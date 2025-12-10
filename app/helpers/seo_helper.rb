# frozen_string_literal: true

module SeoHelper
  # Helper to safely get asset URL, returns nil if asset doesn't exist
  def safe_asset_url(asset_name)
    asset_url(asset_name)
  rescue Propshaft::MissingAssetError
    nil
  end

  # Generate JSON-LD structured data for a blog post (Article schema)
  def blog_post_structured_data(post)
    data = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => post.excerpt.presence || truncate(strip_tags(post.content), length: 160),
      "datePublished" => post.published_at&.iso8601,
      "dateModified" => post.updated_at.iso8601,
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => post_url(post)
      },
      "wordCount" => post.content.to_s.split.size,
      "articleBody" => strip_tags(post.content).truncate(5000)
    }

    # Add author information
    if post.author
      data["author"] = {
        "@type" => "Person",
        "name" => post.author.email.split("@").first.titleize
      }
    end

    # Add publisher information
    publisher = {
      "@type" => "Organization",
      "name" => "Deployable"
    }

    logo_url = safe_asset_url("icon.png")
    if logo_url
      publisher["logo"] = {
        "@type" => "ImageObject",
        "url" => logo_url
      }
    end

    data["publisher"] = publisher

    # Add featured image if present
    if post.featured_image_url.present?
      data["image"] = {
        "@type" => "ImageObject",
        "url" => post.featured_image_url
      }
    end

    # Add category if present
    data["articleSection"] = post.blog_category.name if post.blog_category

    # Add tags as keywords
    if post.blog_tags.any?
      data["keywords"] = post.blog_tags.pluck(:name).join(", ")
    end

    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end

  # Generate JSON-LD structured data for blog index (Blog schema)
  def blog_index_structured_data
    publisher = {
      "@type" => "Organization",
      "name" => "Deployable"
    }

    logo_url = safe_asset_url("icon.png")
    if logo_url
      publisher["logo"] = {
        "@type" => "ImageObject",
        "url" => logo_url
      }
    end

    data = {
      "@context" => "https://schema.org",
      "@type" => "Blog",
      "name" => "Deployable Blog",
      "description" => "Expert insights, industry trends, and resources to help you succeed",
      "url" => posts_url,
      "publisher" => publisher
    }

    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end

  # Generate breadcrumb structured data
  def breadcrumb_structured_data(breadcrumbs)
    items = breadcrumbs.each_with_index.map do |crumb, index|
      {
        "@type" => "ListItem",
        "position" => index + 1,
        "name" => crumb[:name],
        "item" => crumb[:url]
      }
    end

    data = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items
    }

    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end

  # Generate organization structured data
  def organization_structured_data
    data = {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "Deployable",
      "url" => root_url,
      "sameAs" => []
    }

    logo_url = safe_asset_url("icon.png")
    data["logo"] = logo_url if logo_url

    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
end
