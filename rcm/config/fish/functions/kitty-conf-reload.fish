function kitty-conf-reload --wraps='pkill -SIGUSR1 kitty' --description 'alias kitty-conf-reload=pkill -SIGUSR1 kitty'
  pkill -SIGUSR1 kitty $argv
        
end
