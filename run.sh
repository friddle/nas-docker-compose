cd $(dirname $0)
DATA_COMPOSE_FILE=""
FORCE_ARGS=""
for i in "$@"; do
  case $i in
    --project=*)
      PROJECT="${i#*=}"
      shift # past argument=value
      ;;
    --service=*)
      SERVICE="${i#*=}"
      shift
      ;;
    --force)
      FORCE_ARGS="--force-recreate"
      shift
      ;;
    --data)
      DATA_COMPOSE_FILE="-f ./services/compose-yunwei-data.yml"
      echo DATA_COMPOSE_FILE
      shift
      ;;
    --action=*)
      ACTION="${i#*=}"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
done


function init()
{
  source ./BASE_ENV.env
}


function up()
{
    init
    docker-compose  ${DATA_COMPOSE_FILE} \
       -f ${PROJECT} \
       --env-file=./BASE_ENV.env \
       up ${SERVICE} ${FORCE_ARGS}\
       -d 

    echo "
    docker-compose  ${DATA_COMPOSE_FILE} \
       -f ${PROJECT} \
       --env-file=./BASE_ENV.env \
       up ${SERVICE} ${FORCE_ARGS}\
       -d 
    "


}

function other(){
    init
    docker-compose ${DATA_COMPOSE_FILE} -f ${SERVICE_FOLDER}/compose-${PROJECT}.yml \
       ${ACTION} ${SERVICE}

}

echo $ACTION

case $ACTION in
    "up")
      up
      ;;
    "help")
       help
       ;;
    *)
    other
esac
