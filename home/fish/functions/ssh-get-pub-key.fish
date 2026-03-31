
function ssh-get-pub-key
  switch (count $argv)
    case 0
      echo "No domains entered"
      exit 1

    case 1
      set -l pubkey (ssh-keyscan -t rsa $argv 2>&1)
      set -l fingerprint (ssh-keygen -v -lf (echo $pubkey[2] | psub) 2>&1)
      set -l lines (string split \n $pubkey)

      echo $pubkey[1]

      for i in (seq (math (count $fingerprint) - 0))
        echo \# $fingerprint[$i]
      end

      echo $pubkey[2]

    case '*'
      for domain in (string split \n $argv | sort)
        ssh-get-pub-key $domain
      end
  end
end
