require 'gepub'

STATES = [:COPY, :SKIP_SCRIPT, :SKIP_NAV, :SKIP_HEADER]

def handle_title line
  raise line unless line =~ /^\s*<title>(.*)<\/title>/
  better_title = $1
  raise better_title unless better_title =~ /(.*) \/ Real World OCaml$/
  return $1
end

def prepare_filtered_pages_in_order
  # gepub apparently changes dir to workdir ...
  files = File.readlines("../list_of_orig_pages")
  files.each do |fn|
    fn.strip!
    nude_fn = "#{fn}.nude.html"

    # we're in nav, ignore
    state = :COPY
    omg_doc_title = "??" # gepub builer interferes with variable naming, would have used `title`, sorry
    File.open(fn) do |input|
      File.open(nude_fn, 'w') do |output|
        input.each do |line|
          case state 
          when :COPY 
            next if line =~ /^\s*<script.*<\/script>/
            if line =~ /^\s*<script/
              state = :SKIP_SCRIPT
              next
            end
            if line =~ /^\s*<nav/
              state = :SKIP_NAV
              next
            end
            if line =~ /^\s*<header/
              state = :SKIP_HEADER
              next
            end
            if line =~ /^\s*<title>/
              omg_doc_title = handle_title line
            end
            output.print line
          when :SKIP_SCRIPT
            state = :COPY if line =~ /^\s*<\/script>/
            next
          when :SKIP_NAV
            state = :COPY if line =~ /^\s*<\/nav>/
            next
          when :SKIP_HEADER
            state = :COPY if line =~ /^\s*<\/header>/
            next
          else
            raise :hell
          end #switch
        end #each
      end #output
    end #input
    yield nude_fn,omg_doc_title
  end
end

builder = GEPUB::Builder.new {
  language          'en'
  unique_identifier 'https://realworldocaml.org/', 'BookID', 'URL'
  title             'Real World OCaml'
  subtitle          'Functional Programming for the Masses'
  creator           ' --- '
  date              Time.now
  
  resources(:workdir => './realworldocaml.org') {
    cover_image 'cover_small.png' => 'media/img/coversmall.png'
    ordered {
      prepare_filtered_pages_in_order do |filtered_fn, title|
        file filtered_fn
        heading title
      end
    }
  }
}
builder.generate_epub("ocaml.epub")
