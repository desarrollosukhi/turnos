<script setup lang="ts">
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import { onBeforeUnmount } from 'vue'

const props = defineProps<{
  modelValue: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const editor = useEditor({
  content: props.modelValue,
  extensions: [StarterKit],
  onUpdate: ({ editor }) => {
    emit('update:modelValue', editor.getHTML())
  },
})

onBeforeUnmount(() => {
  editor.value?.destroy()
})
</script>

<template>
  <div class="tiptap-editor rounded-lg border overflow-hidden" :style="{ borderColor: 'var(--color-border)' }">
    <!-- Toolbar -->
    <div v-if="editor" class="flex items-center gap-1 p-1 border-b" :style="{ borderColor: 'var(--color-border)', backgroundColor: 'var(--color-primary-subtle)' }">
      <button @click="editor.chain().focus().toggleBold().run()"
        :class="['px-2 py-1 rounded text-sm font-bold cursor-pointer hover:opacity-80', editor.isActive('bold') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Negrita">B</button>
      <button @click="editor.chain().focus().toggleItalic().run()"
        :class="['px-2 py-1 rounded text-sm italic cursor-pointer hover:opacity-80', editor.isActive('italic') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Cursiva">I</button>
      <button @click="editor.chain().focus().toggleStrike().run()"
        :class="['px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80', editor.isActive('strike') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Tachado"><s>S</s></button>
      <span class="w-px h-4" :style="{ backgroundColor: 'var(--color-border)' }"></span>
      <button @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
        :class="['px-2 py-1 rounded text-sm font-bold cursor-pointer hover:opacity-80', editor.isActive('heading', { level: 2 }) ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Título">H</button>
      <button @click="editor.chain().focus().toggleBulletList().run()"
        :class="['px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80', editor.isActive('bulletList') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Lista con puntos">☰</button>
      <button @click="editor.chain().focus().toggleOrderedList().run()"
        :class="['px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80', editor.isActive('orderedList') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Lista numerada">1.</button>
      <button @click="editor.chain().focus().toggleBlockquote().run()"
        :class="['px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80', editor.isActive('blockquote') ? 'bg-white shadow' : '']"
        :style="{ color: 'var(--color-text)' }" title="Cita">❝</button>
      <span class="w-px h-4" :style="{ backgroundColor: 'var(--color-border)' }"></span>
      <button @click="editor.chain().focus().setHorizontalRule().run()"
        class="px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80"
        :style="{ color: 'var(--color-text)' }" title="Línea horizontal">—</button>
      <button @click="editor.chain().focus().undo().run()"
        class="px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80"
        :style="{ color: 'var(--color-text)' }" title="Deshacer">↩</button>
      <button @click="editor.chain().focus().redo().run()"
        class="px-2 py-1 rounded text-sm cursor-pointer hover:opacity-80"
        :style="{ color: 'var(--color-text)' }" title="Rehacer">↪</button>
    </div>
    <!-- Editor -->
    <EditorContent :editor="editor" class="tiptap-content min-h-[120px] p-3 focus:outline-none" />
  </div>
</template>

<style>
.tiptap-content .ProseMirror {
  outline: none;
  min-height: 120px;
}
.tiptap-content .ProseMirror h2 {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0.5rem 0;
}
.tiptap-content .ProseMirror ul {
  list-style-type: disc;
  padding-left: 1.5rem;
}
.tiptap-content .ProseMirror ol {
  list-style-type: decimal;
  padding-left: 1.5rem;
}
.tiptap-content .ProseMirror blockquote {
  border-left: 3px solid #e5e7eb;
  padding-left: 1rem;
  color: #6b7280;
  font-style: italic;
}
.tiptap-content .ProseMirror hr {
  border-color: #e5e7eb;
  margin: 1rem 0;
}
.tiptap-content .ProseMirror p {
  margin: 0.25rem 0;
}
</style>
