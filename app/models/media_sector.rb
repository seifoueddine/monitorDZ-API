# frozen_string_literal: true

class MediaSector < ApplicationRecord
  belongs_to :sector
  belongs_to :medium
end
