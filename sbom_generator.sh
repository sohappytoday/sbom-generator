# SOLUTION
source solution-name.sh

# NODE
NODE=$(hostname)

# NAMESPACE
NAMESPACE_1=kube-system
NAMESPACE_2=devai-cluster

# SBOM FILE FORMAT
SBOM_FILE_FORMAT=cyclonedx
SBOM_FILE_UPPER_FORMAT=${SBOM_FILE_FORMAT^^}

# SBOM OUTPUT FORMAT
SBOM_OUTPUT_FORMAT=json


echo ""
echo ""
echo "==========================================="
echo "==      SBOM 파일 포맷 : CycloneDX       =="
echo "==      CycloneDX 생성 툴 :  Syft        =="    
echo "==========================================="
echo ""
echo ""
echo "==========================================="
echo "==        솔루션 SBOM 제작 목록          =="
echo "==========================================="
echo "==                                       =="
echo "==                                       =="

for i in "${!SOLUTION_NAMES[@]}"; do
  printf "== %-37s ==\n" \
    "${SOLUTION_NAMES[$i]}:${COMPARE_SOLUTION_VERSIONS[$i]}"
done
echo "==========================================="
echo "제작자 : 그로밋(김지오) 인턴"

# PRIORITY_NODES
readarray -t PRIORITY_NODES < <( kubectl get nodes --no-headers | awk '$2 == "Ready" {print $1}' | sort -V)
echo "Node Priority(Order) : ${PRIORITY_NODES[@]}"
echo ""


ALL_PODS=$(kubectl get pods -A \-o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.nodeName}{"\n"}{end}')

should_skip() {
  local solution_name="$1"
  local current_node="$2"

  local CURRENT_INDEX=-1

  for idx in "${!PRIORITY_NODES[@]}"; do
    if [[ "${PRIORITY_NODES[$idx]}" == "$current_node" ]]; then
      CURRENT_INDEX=$idx
      break
    fi
  done

  if [[ $CURRENT_INDEX -eq -1 ]]; then
    return 1
  fi

  for ((j=0; j<CURRENT_INDEX; j++)); do
    local PRIOR_NODE="${PRIORITY_NODES[$j]}"

    EXIST_POD=$(echo "$ALL_PODS" | awk -v name="$solution_name" -v node="$PRIOR_NODE" '$2 ~ name && $3 == node {print $2; exit}')

    if [[ -n "$EXIST_POD" ]]; then
      echo "이전 node에 pod가 존재합니다."
      echo ""
      return 0   # skip
    fi
  done

  return 1   # go ahead
}

#################
# sbom 파일 생성 #
#################

for i in "${!SOLUTION_NAMES[@]}"; do

echo "==========================================="
echo ""
echo "*****  ${SOLUTION_NAMES[$i]}  *****"
echo ""

SOLUTION_POD=$(echo "$ALL_PODS" | awk -v name="${SOLUTION_NAMES[$i]}" -v node="$NODE" '$2 ~ name && $3 == node {print $2; exit}')

if [ -z "$SOLUTION_POD" ]; then
    echo "현재 노드에서 실행 중인 Pod 없습니다."
    echo ""
fi


if should_skip "${SOLUTION_NAMES[$i]}" "$NODE"; then
    continue
fi

# image name에 -로 연결되는 것과 _로 연결되는 것 모두 탐색
name1="${SOLUTION_NAMES[$i]}"
name2="${SOLUTION_NAMES[$i]//-/_}"

read IMAGE_NAME IMAGE_VERSION <<< "$(
  podman images --format "{{.Repository}} {{.Tag}}" \
  | awk -F'/' -v n1="$name1" -v n2="$name2" '{
    img=$NF
    if (img ~ n1 || img ~ n2) {
    print $0
    exit
    }
  }'
)"

if [[ -z "$IMAGE_NAME" ]]; then
  echo "솔루션명의 이미지가 존재하지 않습니다. : ${SOLUTION_NAMES[$i]}"
  echo ""
  continue
else
  echo "Image : $IMAGE_NAME:$IMAGE_VERSION"
fi


mkdir -p $SAVE_DIR_PATH
syft $IMAGE_NAME:$IMAGE_VERSION -o ${SBOM_FILE_FORMAT}-${SBOM_OUTPUT_FORMAT} > $SAVE_DIR_PATH/${SOLUTION_NAMES[i]}_v${IMAGE_VERSION#v}_SBOM_${SBOM_FILE_UPPER_FORMAT}.${SBOM_OUTPUT_FORMAT}

echo ""
echo "=========="
echo "= Result ="
echo "=========="
echo ""
echo "solution name : ${SOLUTION_NAMES[$i]}"
echo "solution version : ${COMPARE_SOLUTION_VERSIONS[$i]}"
echo "created version : $IMAGE_VERSION"

echo ""
echo "SBOM 파일 생성 완료"
echo "file name : ${SOLUTION_NAMES[i]}_v${IMAGE_VERSION#v}_SBOM_${SBOM_FILE_UPPER_FORMAT}.${SBOM_OUTPUT_FORMAT}"
echo ""
echo "==========================================="
done