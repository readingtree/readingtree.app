const { createApp, ref } = Vue;

createApp({
    setup() {
        const treeId = window.location.href.split(/\//).pop();
        const tree = fetch(`/api/trees/${treeId}`);
        const message = ref('Hello vue!');

        return {
            message
        };
    }
}).mount('#app');
