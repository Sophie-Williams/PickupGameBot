module PickupBot::Commands
  class Error
    def self.run(telegram_bot, message, exception)
      new(telegram_bot, message).run
    end

    def initialize(telegram_bot, message)
      @telegram_bot = telegram_bot
      @message = message
    end

    def run
      telegram_bot.api.send_message(
        chat_id: message.chat.id,
        text: I18n.t('bot.command_does_not_exist', username: username)
      )
    end

    private

    attr_reader :telegram_bot, :message

    def username
      message.from.username || message.from.first_name
    end
  end
end
