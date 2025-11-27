# frozen_string_literal: true

module MembersHelper
  def role_badge_class(role)
    case role.to_s
    when "owner"
      "bg-purple-100 text-purple-800"
    when "admin"
      "bg-blue-100 text-blue-800"
    when "member"
      "bg-green-100 text-green-800"
    when "guest"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def available_roles_for_select(current_membership)
    if current_membership&.owner?
      [ [ "Admin", "admin" ], [ "Member", "member" ], [ "Guest", "guest" ] ]
    else
      [ [ "Member", "member" ], [ "Guest", "guest" ] ]
    end
  end
end
