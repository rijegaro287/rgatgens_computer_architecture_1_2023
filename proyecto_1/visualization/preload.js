window.addEventListener('DOMContentLoaded', () => {
  const imagesContainer = document.getElementById('images-container');
  const generateButton = document.getElementById('generate-button');
  generateButton.addEventListener('click', () => {
    imagesContainer.style.display = 'flex';
    setTimeout(() => {
      imagesContainer.style.visibility = 'visible';
      imagesContainer.style.opacity = '1';
    }, 50);

  });
});