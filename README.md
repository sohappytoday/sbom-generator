## SBOM 파일
SBOM 파일은 소프트웨어 안에 포함된 모든 구성 요소(패키지, 라이브러리, 의존성 등)의 목록을 정리한 문서입니다.
실제 고객사에서 요청한 오픈 소스 솔루션 SBOM 파일을 제공하기 위해 만들었으나, 하나의 Shell Script를 이용하여 이후 solution name이 변경되더라도 사용할 수 있도록 처리하였습니다.

### SBOM 표준 포맷
CycloneDX

### SBOM 포맷 생성 툴
Syft (CycloneDX, SPDX 모두 호환)

### 개발 사항
1\. 최적화를 위해 노드를 탐색하여 각 노드에 존재하는 이미지 파일들만 SBOM 파일로 생성하였습니다.
2\. NameSpace는 불필요한 탐색 범위를 줄이기 위해 kube-system, devai-cluster 하드코딩하였습니다.
3\. Node를 번호대로 우선순위를 두어, 특정 솔루션 이미지가 이전 노드에서 Pod가 존재하면 건너뛰도록 설계하여, SBOM 파일이 각 노드마다 중복되지 않도록 하였습니다.
4\. Pod가 Running 상태가 아니라면 이미지 파일이 존재하더라도 사용하지 않는 이미지라 판단하여 건너뛰도록 설계하였습니다.
5\. `solution-name.sh` 내 하드 코딩을 줄이기 위해 solution-name을 이용하여 image_name 및 image_version을 탐색하고 syft 툴을 이용하여 CycloneDX 포맷 SBOM file을 생성하였습니다.