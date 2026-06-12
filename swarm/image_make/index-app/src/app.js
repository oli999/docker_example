// src/app.js

// 화면의 데이터 출력 공간 확보
const resultArea = document.getElementById('result');

// 1. 회원 목록 조회 버튼 이벤트 바인딩
document.getElementById('btn-member').addEventListener('click', () => {
    resultArea.textContent = "회원 데이터를 불러오는 중입니다...";
    
    // Nginx 라우터가 /members 경로를 보고 member-app 부대로 토스합니다.
    fetch('/members')
        .then(response => {
            if (!response.ok) throw new Error(`HTTP 에러! 상태코드: ${response.status}`);
            return response.json();
        })
        .then(data => {
            // 받아온 JSON을 들여쓰기 2칸 처리해서 화면에 이쁘게 출력
            resultArea.textContent = JSON.stringify(data, null, 2);
        })
        .catch(error => {
            resultArea.textContent = " 회원 조회 에러 발생:\n" + error.message;
        });
});

// 2. 글 목록 조회 버튼 이벤트 바인딩
document.getElementById('btn-post').addEventListener('click', () => {
    resultArea.textContent = "게시글 데이터를 불러오는 중입니다...";
    
    // Nginx 라우터가 /posts 경로를 보고 post-app 부대로 토스합니다.
    fetch('/posts')
        .then(response => {
            if (!response.ok) throw new Error(`HTTP 에러! 상태코드: ${response.status}`);
            return response.json();
        })
        .then(data => {
            resultArea.textContent = JSON.stringify(data, null, 2);
        })
        .catch(error => {
            resultArea.textContent = "글 조회 에러 발생:\n" + error.message;
        });
});