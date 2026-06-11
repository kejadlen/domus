function captureApp() {
  return {
    state: 'capture',
    preview: null,
    dragging: false,

    handleFile(file) {
      if (!file) return;
      this.preview = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
      this.state = 'saved';
    },

    onFileInput(e) {
      this.handleFile(e.target.files[0]);
    },

    onDrop(e) {
      this.dragging = false;
      const file = e.dataTransfer?.files[0];
      if (file) {
        this.$refs.fileInput.files = e.dataTransfer.files;
        this.handleFile(file);
      }
    },

    reset() {
      if (this.preview) URL.revokeObjectURL(this.preview);
      this.state = 'capture';
      this.preview = null;
      this.$refs.fileInput.value = '';
      this.$refs.cameraInput.value = '';
    }
  }
}
