'use client';

import { useState } from 'react';

interface MenuItemFormProps {
  onSubmit: (name: string) => void;
  initialValue?: string;
  submitLabel?: string;
}

export default function MenuItemForm({ 
  onSubmit, 
  initialValue = '', 
  submitLabel = 'Add Item' 
}: MenuItemFormProps) {
  const [name, setName] = useState(initialValue);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      onSubmit(name.trim());
      if (!initialValue) {
        setName('');
      }
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <input
        type="text"
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Enter menu item name"
        className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
      />
      <button
        type="submit"
        className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        {submitLabel}
      </button>
    </form>
  );
}