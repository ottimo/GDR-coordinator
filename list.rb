class List < Ohm::Model
  attribute :recipient
  attribute :days
  attribute :created_at

  unique :recipient
  index :recipient

  def checktime
    oldtime = Time.parse self.created_at.to_s
    update created_at: Time.now.to_s if oldtime.strftime('%U') != Time.now.strftime('%U')
  end
end
