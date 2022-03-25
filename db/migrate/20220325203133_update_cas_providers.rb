class UpdateCasProviders < ActiveRecord::Migration[5.2]
  def change
    User.find_each do |user|
      user.update_attribute(:provider, 'CAS')
    end
  end
end
