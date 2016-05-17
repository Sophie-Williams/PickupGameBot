module Commands
  class Join
    def self.run(telegram_bot, message)
      new(telegram_bot, message).run
    end

    def initialize(telegram_bot, message)
      @telegram_bot = telegram_bot
      @message = message
    end

    def run
      if game_exists?
        current_player = Player.find_or_create_by(telegram_user_id: message.from.id)
        pics = telegram_bot.api.get_user_profile_photos(user_id: message.from.id)
        file_id = pics["result"]["photos"][0][2]["file_id"]
        file = telegram_bot.api.get_file(file_id: file_id)
        file_path = file["result"]["file_path"]
        photo_url = "https://api.telegram.org/file/bot#{ENV["TELEGRAM_TOKEN"]}/#{file_path}"
        current_player.avatar = URI.parse(photo_url)
        current_player.first_name = message.from.first_name
        current_player.last_name = message.from.last_name
        current_player.username = message.from.username
        current_player.save

        attendence = Attendance.new(game: current_game, player: current_player)
        attendence.save
        telegram_bot.api.send_message(
          chat_id: message.chat.id,
          text: I18n.t(
            "bot.joined_game",
            username: username,
            players: players
          )
        )
      else
        telegram_bot.api.send_message(
          chat_id: message.chat.id,
          text: I18n.t("bot.no_game", username: username)
        )
      end
    end

    private

    attr_reader :telegram_bot, :message

    def game_exists?
      Game.active.exists?(chat_id: @message.chat.id)
    end

    def current_game
      Game.active.find_by_chat_id(@message.chat.id)
    end

    def players
      if current_game.required_players > 0
        "#{current_game.players.count} / #{current_game.required_players}"
      else
        "#{current_game.players.count}"
      end
    end

    def username
      message.from.username || message.from.first_name
    end
  end
end
