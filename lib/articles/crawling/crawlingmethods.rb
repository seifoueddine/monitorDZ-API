# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # Crawling Methods
    module Crawlingmethods
      # change translate date
      def change_translate_date(d)
        d.split.map do |m|
          case m.downcase
          when 'Janvier,'.downcase
            'January'
          when 'Février,'.downcase
            'February'
          when 'Mars,'.downcase
            'March'
          when 'Avril,'.downcase
            'April'
          when 'Mai,'.downcase
            'May'
          when 'Juin,'.downcase
            'June'
          when 'Juillet,'.downcase
            'July'
          when 'Octobre,'.downcase
            'October'
          when 'Novembre,'.downcase
            'November'
          when 'Décembre,'.downcase
            'December'
          when 'Septembre,'.downcase
            'September'
          when 'août,'.downcase
            'August'
          when 'Janvier'.downcase
            'January'
          when 'Février'.downcase
            'February'
          when 'Mars'.downcase
            'March'
          when 'Avril'.downcase
            'April'
          when 'Mai'.downcase
            'May'
          when 'Juin'.downcase
            'June'
          when 'Juillet'.downcase
            'July'
          when 'Octobre'.downcase
            'October'
          when 'Novembre'.downcase
            'November'
          when 'Décembre'.downcase
            'December'
          when 'Septembre'.downcase
            'September'
          when 'août'.downcase
            'August'

          when 'جانفي'.downcase
            'January'
          when 'فيفري'.downcase
            'February'
          when 'مارس'.downcase
            'March'
          when 'افريل'.downcase
            'April'
          when 'ماي'.downcase
            'May'
          when 'جوان'.downcase
            'June'
          when 'جويلية'.downcase
            'July'
          when 'جولية'.downcase
            'July'
          when 'أكتوبر'.downcase
            'October'
          when 'نوفمبر'.downcase
            'November'
          when 'ديسمبر'.downcase
            'December'
          when 'سبتمبر'.downcase
            'September'
          when 'اوت'.downcase
            'August'

          when 'جانفي،'.downcase
            'January'
          when 'فيفري،'.downcase
            'February'
          when 'مارس،'.downcase
            'March'
          when 'افريل،'.downcase
            'April'
          when 'ماي،'.downcase
            'May'
          when 'جوان،'.downcase
            'June'
          when 'جويلية،'.downcase
            'July'
          when 'جولية،'.downcase
            'July'
          when 'أكتوبر،'.downcase
            'October'
          when 'نوفمبر،'.downcase
            'November'
          when 'نونمبر،'.downcase
            'November'
          when 'ديسمبر،'.downcase
            'December'
          when 'سبتمبر،'.downcase
            'September'
          when 'اوت،'.downcase
            'August'

          when 'يناير'.downcase
            'January'
          when 'فبراير'.downcase
            'February'
          when 'ابريل'.downcase
            'April'
          when 'أبريل'.downcase
            'April'
          when 'مايو'.downcase
            'May'
          when 'يونيو'.downcase
            'June'
          when 'يوليو'.downcase
            'July'
          when 'أغسطس'.downcase
            'August'

          else
            m
          end
        end.join(' ')
      end
    end
  end
end